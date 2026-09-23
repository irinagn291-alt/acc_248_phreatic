import SwiftUI

/// Amount picker. A stranger chooses how much they just drank; the gold
/// button commits that sip. Nav-bar Close is the only dismiss control.
struct DialView: View {
    @ObservedObject var store: AquiferStore
    let level: WellLevel
    var notice: String?
    var retry: (() -> Void)?
    var close: () -> Void

    @State private var selectedMl: Int
    @State private var busy = false
    @State private var committed = false

    private let presets = [150, 250, 500]
    private let wheelChoices = [50, 100, 150, 200, 250, 300, 350, 400, 500, 750, 1_000]

    init(
        store: AquiferStore,
        level: WellLevel,
        notice: String? = nil,
        retry: (() -> Void)? = nil,
        close: @escaping () -> Void
    ) {
        self.store = store
        self.level = level
        self.notice = notice
        self.retry = retry
        self.close = close
        _selectedMl = State(initialValue: SipVolume.sanitized(store.file.sipVolumeMl))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let notice {
                    errorPage(notice)
                } else {
                    pickerPage
                }
            }
            .background(ColorToken.background.ignoresSafeArea())
            .navigationTitle("Dial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close", action: close)
                }
            }
        }
    }

    private var pickerPage: some View {
        VStack(alignment: .leading, spacing: SpaceToken.md) {
            Text("\(AquiferFormat.millilitres(level.remainingMl)) ml remaining")
                .font(TypeToken.display(size: 40))
                .foregroundStyle(ColorToken.ink)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("Choose how much you just drank.")
                .font(TypeToken.body)
                .foregroundStyle(ColorToken.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("The number above falls as the day drains. A logged sip adds that volume at once.")
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: SpaceToken.xs) {
                ForEach(presets, id: \.self) { volume in
                    Button {
                        selectedMl = volume
                    } label: {
                        Text(AquiferFormat.millilitresLabeled(volume))
                            .font(TypeToken.body.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(selectedMl == volume ? ColorToken.background : ColorToken.ink)
                            .frame(maxWidth: .infinity, minHeight: SpaceToken.unit * 6)
                            .background(
                                selectedMl == volume ? ColorToken.accent : ColorToken.surface,
                                in: RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AquiferFormat.millilitresLabeled(volume))
                }
            }

            WellWheel(
                values: wheelChoices,
                selection: $selectedMl,
                accessibilityName: "Custom sip size",
                label: AquiferFormat.millilitresLabeled
            )
        }
        .padding(SpaceToken.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .safeAreaInset(edge: .bottom, spacing: SpaceToken.sm) {
            Button(action: commit) {
                Text(committed ? "Logged" : "Log \(AquiferFormat.millilitresLabeled(selectedMl))")
            }
            .buttonStyle(WellButtonStyle(kind: .primary, committed: committed))
            .disabled(busy)
            .padding(.horizontal, SpaceToken.md)
            .padding(.bottom, SpaceToken.sm)
            .accessibilityLabel("Log \(AquiferFormat.millilitresLabeled(selectedMl))")
            .accessibilityHint("Adds this sip to today.")
        }
    }

    private func errorPage(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: SpaceToken.md) {
            Text("Dial could not load")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            Text(message)
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
            if let retry {
                Button("Try again", action: retry)
                    .buttonStyle(WellButtonStyle(kind: .secondary))
            }
            Button("Close", action: close)
                .buttonStyle(WellButtonStyle(kind: .primary))
        }
        .padding(SpaceToken.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func commit() {
        guard !busy else { return }
        busy = true
        if store.logSip(volumeMl: selectedMl) != nil {
            WellHaptics.commit()
            committed = true
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                committed = false
                busy = false
            }
        } else {
            busy = false
        }
    }
}
