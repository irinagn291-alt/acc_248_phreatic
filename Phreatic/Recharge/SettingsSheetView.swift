import SwiftUI

/// Settings sheet. Intake, bonus, sip volume, goal, sources, contact,
/// re-run onboarding, clear today, reset all.
struct SettingsSheetView: View {
    @ObservedObject var store: AquiferStore
    var rerunIntake: () -> Void
    var close: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var confirmClearToday = false
    @State private var confirmReset = false
    @State private var retryBusy = false
    @State private var resetBusy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SpaceToken.md) {
                    if let notice = store.recoveryNotice {
                        WellLoadErrorBanner(message: notice, retry: retry)
                    }

                    intakeSection
                    hairline
                    bonusSection
                    hairline
                    sipSection
                    hairline
                    goalRow
                    hairline
                    sourcesSection
                    hairline
                    contactRow
                    versionRow
                    hairline
                    Button("Walk through setup again", action: rerunIntake)
                        .buttonStyle(WellButtonStyle(kind: .secondary))
                    Button("Clear today") {
                        confirmClearToday = true
                    }
                    .buttonStyle(WellButtonStyle(kind: .destructive))
                    Button("Reset all data") {
                        confirmReset = true
                    }
                    .buttonStyle(WellButtonStyle(kind: .destructive))
                    .disabled(resetBusy)
                }
                .padding(SpaceToken.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(ColorToken.background.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close", action: close)
                }
            }
            .confirmationDialog(
                clearTodayTitle,
                isPresented: $confirmClearToday,
                titleVisibility: .visible
            ) {
                Button("Remove today's sips", role: .destructive) {
                    store.clearToday()
                }
                Button("Keep them", role: .cancel) {}
            } message: {
                Text("The sips for \(AquiferFormat.dayTitle(DayKey.from(Date()))) are removed.")
            }
            .confirmationDialog(
                "Reset all data",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset this device", role: .destructive) {
                    resetBusy = true
                    Task {
                        await store.resetAllData()
                        resetBusy = false
                        rerunIntake()
                    }
                }
                Button("Keep everything", role: .cancel) {}
            } message: {
                Text("Every day and setting on this device is removed.")
            }
        }
    }

    private var clearTodayTitle: String {
        "Clear \(AquiferFormat.dayTitle(DayKey.from(Date())))"
    }

    private var intakeSection: some View {
        VStack(alignment: .leading, spacing: SpaceToken.sm) {
            Text("Body and hours")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            labeledRow("Body weight", AquiferFormat.kilograms(store.file.intake.bodyKg))
            WellWheel(
                values: Array(stride(from: 20, through: 300, by: 1)),
                selection: weightBinding,
                accessibilityName: "Body weight",
                label: { AquiferFormat.kilograms(Double($0)) }
            )
            HStack(alignment: .top, spacing: SpaceToken.sm) {
                hourPicker("Wake", selection: wakeBinding)
                hourPicker("Sleep", selection: sleepBinding)
            }
        }
    }

    private var bonusSection: some View {
        VStack(alignment: .leading, spacing: SpaceToken.sm) {
            Text("Activity bonus")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            Text("Still water, a stirred day, or a doubled draw. The bonus is added before the goal is rounded.")
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: SpaceToken.xs) {
                ForEach(DrawBonus.allCases, id: \.rawValue) { bonus in
                    Button {
                        store.setActivityBonus(bonus.rawValue)
                    } label: {
                        Text(bonusLabel(bonus))
                            .font(TypeToken.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(store.file.activityBonusMl == bonus.rawValue ? ColorToken.background : ColorToken.ink)
                            .frame(maxWidth: .infinity, minHeight: SpaceToken.xl)
                            .background(
                                store.file.activityBonusMl == bonus.rawValue ? ColorToken.accent : ColorToken.surface,
                                in: RoundedRectangle(cornerRadius: RadiusToken.chip, style: .continuous)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: RadiusToken.chip, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sipSection: some View {
        VStack(alignment: .leading, spacing: SpaceToken.sm) {
            Text("Default sip")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            labeledRow("Tap volume", AquiferFormat.millilitresLabeled(store.file.sipVolumeMl))
            WellWheel(
                values: sipChoices,
                selection: sipBinding,
                accessibilityName: "Default sip",
                label: AquiferFormat.millilitresLabeled
            )
        }
    }

    private var goalRow: some View {
        HStack {
            Text("Daily goal")
                .font(TypeToken.body)
                .foregroundStyle(ColorToken.ink)
            Spacer(minLength: SpaceToken.xs)
            Text(AquiferFormat.millilitresLabeled(store.file.goal.millilitres))
                .font(TypeToken.secondary)
                .foregroundStyle(ColorToken.muted)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: SpaceToken.sm) {
            Text("Sources")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            Text("The 33 millilitres per kilogram figure comes from public hydration references. This app is not medical advice.")
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(HydrationCitation.bundled) { citation in
                Button {
                    openURL(citation.url)
                } label: {
                    VStack(alignment: .leading, spacing: SpaceToken.unit / 2) {
                        Text(citation.title)
                            .font(TypeToken.body)
                            .foregroundStyle(ColorToken.ink)
                        Text(citation.publisher)
                            .font(TypeToken.caption)
                            .foregroundStyle(ColorToken.muted)
                    }
                    .frame(maxWidth: .infinity, minHeight: SpaceToken.xl, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var contactRow: some View {
        Button {
            if let url = URL(string: "https://phreatic-well.pro/contact") {
                openURL(url)
            }
        } label: {
            Text("Contact Phreatic")
                .font(TypeToken.body)
                .foregroundStyle(ColorToken.ink)
                .frame(maxWidth: .infinity, minHeight: SpaceToken.xl, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var versionRow: some View {
        HStack {
            Text("Version")
                .font(TypeToken.body)
                .foregroundStyle(ColorToken.ink)
            Spacer(minLength: SpaceToken.xs)
            Text(versionText)
                .font(TypeToken.secondary)
                .foregroundStyle(ColorToken.muted)
                .monospacedDigit()
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(ColorToken.muted.opacity(0.35))
            .frame(height: SpaceToken.hairline)
    }

    private var sipChoices: [Int] {
        [50, 100, 150, 200, 250, 300, 350, 400, 500, 750, 1000]
    }

    private var weightBinding: Binding<Int> {
        Binding(
            get: { Int(store.file.intake.bodyKg.rounded()) },
            set: { newValue in
                store.setIntake(
                    WakeIntake(bodyKg: Double(newValue), wakeHour: store.file.wakeHour, sleepHour: store.file.sleepHour)
                )
            }
        )
    }

    private var wakeBinding: Binding<Int> {
        Binding(
            get: { store.file.wakeHour },
            set: { newValue in
                store.setIntake(
                    WakeIntake(bodyKg: store.file.bodyKg, wakeHour: newValue, sleepHour: store.file.sleepHour)
                )
            }
        )
    }

    private var sleepBinding: Binding<Int> {
        Binding(
            get: { store.file.sleepHour },
            set: { newValue in
                store.setIntake(
                    WakeIntake(bodyKg: store.file.bodyKg, wakeHour: store.file.wakeHour, sleepHour: newValue)
                )
            }
        )
    }

    private var sipBinding: Binding<Int> {
        Binding(
            get: { store.file.sipVolumeMl },
            set: { store.setSipVolume($0) }
        )
    }

    private func hourPicker(_ title: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: SpaceToken.xs) {
            Text(title)
                .font(TypeToken.body)
                .foregroundStyle(ColorToken.ink)
            Text(AquiferFormat.clockHour(selection.wrappedValue))
                .font(TypeToken.secondary)
                .foregroundStyle(ColorToken.muted)
                .monospacedDigit()
            WellWheel(
                values: Array(0..<24),
                selection: selection,
                accessibilityName: title,
                label: AquiferFormat.clockHour
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func bonusLabel(_ bonus: DrawBonus) -> String {
        switch bonus {
        case .still:
            return "0"
        case .stirred:
            return "350"
        case .doubled:
            return "700"
        }
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "-"
        return short
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(TypeToken.body)
                .foregroundStyle(ColorToken.ink)
            Spacer(minLength: SpaceToken.xs)
            Text(value)
                .font(TypeToken.secondary)
                .foregroundStyle(ColorToken.muted)
                .monospacedDigit()
        }
    }

    private func retry() {
        guard !retryBusy else { return }
        retryBusy = true
        Task {
            await store.load()
            retryBusy = false
        }
    }
}
