import SwiftUI

/// Locked chrome. The draining well never leaves. History, Settings, and
/// the ebb-drain sheet arrive over it. Intake is a fullScreenCover until
/// the flag is set. `-ReviewScreen` is read once after that flag is true.
@MainActor
struct WellRootView: View {
    @ObservedObject var store: AquiferStore
    let supportDirectory: URL

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var clock: DrawDownClock
    @State private var isReady = false
    @State private var showIntake = false
    @State private var sheet: WellSheet?
    @State private var reviewConsumed = false
    @State private var sipBusy = false
    @State private var sipCommitted = false
    @State private var activityBusy = false

    init(store: AquiferStore, supportDirectory: URL) {
        self.store = store
        self.supportDirectory = supportDirectory
        _clock = StateObject(wrappedValue: DrawDownClock(store: store))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorToken.background.ignoresSafeArea()
                if isReady {
                    wellPage
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sheet = .settings
                    } label: {
                        Image(systemName: "gearshape")
                            .frame(minWidth: SpaceToken.xl, minHeight: SpaceToken.xl)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isReady, !isFreshDay {
                    bottomBar
                }
            }
        }
        .tint(ColorToken.accent)
        .preferredColorScheme(.dark)
        .task {
            await bootstrap()
        }
        .onAppear {
            if isReady {
                clock.start()
            }
        }
        .onDisappear {
            clock.stop()
        }
        .onChange(of: isReady) { _, ready in
            if ready {
                clock.start()
            }
        }
        .onChange(of: store.file) { _, _ in
            clock.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            Task {
                if phase == .active {
                    clock.start()
                } else {
                    clock.stop()
                    await store.handleScenePhase(isActive: false)
                }
            }
        }
        .fullScreenCover(isPresented: $showIntake) {
            IntakeFlowView { intake in
                store.setIntake(intake)
                store.markIntakeDone()
                showIntake = false
            }
        }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .history:
                HistorySheetView(store: store, close: { sheet = nil })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .settings:
                SettingsSheetView(
                    store: store,
                    rerunIntake: {
                        sheet = nil
                        showIntake = true
                    },
                    close: { sheet = nil }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            case .ebbDrain:
                EbbDrainSheetView(level: clock.level, close: { sheet = nil })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .dial:
                DialView(
                    store: store,
                    level: clock.level,
                    notice: store.recoveryNotice,
                    retry: retryLoad,
                    close: { sheet = nil }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var wellPage: some View {
        VStack(alignment: .leading, spacing: SpaceToken.sm) {
            if let notice = store.recoveryNotice {
                WellLoadErrorBanner(message: notice, retry: retryLoad)
                    .padding(.horizontal, SpaceToken.md)
            }
            WellChrome(level: clock.level)
                .padding(.horizontal, SpaceToken.md)

            if isFreshDay {
                WellEmptyState(logSip: commitSip)
            } else {
                adaptiveWell
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var isWide: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }

    private var adaptiveWell: some View {
        Group {
            if isWide {
                HStack(alignment: .top, spacing: SpaceToken.md) {
                    wellColumn
                        .frame(maxWidth: SpaceToken.xl * 9, maxHeight: .infinity)
                    mechanicPane
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                VStack(alignment: .leading, spacing: SpaceToken.md) {
                    wellColumn
                    mechanicPane
                }
            }
        }
        .padding(.horizontal, SpaceToken.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var wellColumn: some View {
        VStack(alignment: .leading, spacing: SpaceToken.sm) {
            ZStack(alignment: .top) {
                WellCanvas(level: clock.level, reduceMotion: reduceMotion)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                GeometryReader { proxy in
                    let y = proxy.size.height * (1 - Stave.fraction) - (SpaceToken.unit * 3)
                    StaveBandView(side: clock.level.side) {
                        sheet = .history
                    }
                    .offset(y: max(0, y))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: SpaceToken.xl * 5, maxHeight: isWide ? .infinity : SpaceToken.xl * 7)
            .clipped()

            Text(clock.level.side == .safe ? "Still ahead of today's line." : "Behind today's line.")
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.ink)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                sheet = .ebbDrain
            } label: {
                Text("Activity doubles the drain for one hour.")
                    .font(TypeToken.caption)
                    .foregroundStyle(ColorToken.ink)
                    .padding(.vertical, SpaceToken.xs)
                    .frame(maxWidth: .infinity, minHeight: SpaceToken.unit * 6, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("How the well drains")
            .accessibilityHint("Opens the drain explanation.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mechanicPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpaceToken.md) {
                DrainRateCard(level: clock.level, doubled: isDrainDoubled)
                TodaySipTimeline(sips: todaySips) {
                    sheet = .history
                }
                WeekHoldStrip(items: weekItems) { _ in
                    sheet = .history
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: SpaceToken.sm) {
            SipButton(
                volumeMl: store.file.sipVolumeMl,
                committed: sipCommitted,
                enabled: !sipBusy,
                action: commitSip
            )
            Button(action: commitActivity) {
                Text("Double the drain")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .buttonStyle(WellButtonStyle(kind: .secondary))
            .disabled(activityBusy)
            .accessibilityLabel("Log activity")
            .accessibilityHint("Doubles the drain for one hour.")
        }
        .padding(.horizontal, SpaceToken.md)
        .padding(.top, SpaceToken.xs)
        .padding(.bottom, SpaceToken.xs)
        .background(.regularMaterial)
    }

    private var isFreshDay: Bool {
        let today = DayKey.from(clock.now)
        guard let record = store.file.days[today.rawValue] else { return true }
        return record.sips.isEmpty
    }

    private var todaySips: [Sip] {
        let today = DayKey.from(clock.now)
        return store.file.days[today.rawValue]?.sips ?? []
    }

    private var weekItems: [DaySealItem] {
        DaySealGrid.weekItems(from: store.file.days, through: DayKey.from(clock.now))
    }

    private var isDrainDoubled: Bool {
        let today = DayKey.from(clock.now)
        guard let record = store.file.days[today.rawValue] else { return false }
        return DrawDown.mergedActivityWindows(record.activities).contains { $0.contains(clock.now) }
    }

    private func bootstrap() async {
        await DemoSeed.installIfNeeded(directory: supportDirectory, defaults: .standard)
        await store.load()
        showIntake = !store.isIntakeDone
        isReady = true
        clock.start()
        while !store.isIntakeDone {
            if Task.isCancelled { return }
            try? await Task.sleep(for: .milliseconds(200))
        }
        applyReviewHook()
    }

    private func applyReviewHook() {
        let key = ReviewScreenKey.consumeProcessInfo(
            intakeDone: store.isIntakeDone,
            consumed: &reviewConsumed
        )
        guard let key else { return }
        if RootRouter.opensIntake(key) {
            showIntake = true
            return
        }
        sheet = RootRouter.sheet(for: key)
    }

    private func commitSip() {
        guard !sipBusy else { return }
        sipBusy = true
        if store.logSip() != nil {
            WellHaptics.commit()
            sipCommitted = true
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                sipCommitted = false
                sipBusy = false
            }
        } else {
            sipBusy = false
        }
    }

    private func commitActivity() {
        guard !activityBusy else { return }
        activityBusy = true
        if store.logActivity() != nil {
            WellHaptics.commit()
        }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            activityBusy = false
        }
    }

    private func retryLoad() {
        Task {
            await store.load()
            clock.refresh()
        }
    }
}
