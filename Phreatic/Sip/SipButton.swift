import SwiftUI

/// Home verb. A native Button that logs the default sip volume and shows a
/// brief committed state. One haptic on commit.
struct SipButton: View {
    let volumeMl: Int
    let committed: Bool
    let enabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SpaceToken.xs) {
                Image("phr_SipDrop")
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: SpaceToken.md, height: SpaceToken.md)
                    .clipped()
                    .accessibilityHidden(true)
                Text(committed ? "Logged" : "Log a sip")
                Text(AquiferFormat.millilitresLabeled(volumeMl))
                    .font(TypeToken.secondary)
                    .monospacedDigit()
            }
        }
        .buttonStyle(WellButtonStyle(kind: .primary, committed: committed))
        .disabled(!enabled)
        .accessibilityLabel("Log a sip")
        .accessibilityHint("Adds the default sip volume to the well.")
    }
}
