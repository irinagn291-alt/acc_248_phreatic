import SwiftUI

/// Twist screen. The ebb-drain well in words, plus the home canvas as the
/// live surface. Reachable from home and from `-ReviewScreen ebb`.
struct EbbDrainSheetView: View {
    let level: WellLevel
    var close: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SpaceToken.md) {
                    Image("phr_TwistHero")
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: SpaceToken.xl * 5)
                        .clipped()
                        .accessibilityHidden(true)

                    Text("The well drains while you wait")
                        .font(TypeToken.title)
                        .foregroundStyle(ColorToken.ink)

                    Text("At wake the table is full. Body mass sets a ceiling on the fall. The well reaches empty at the sleep hour if you leave it alone.")
                        .font(TypeToken.caption)
                        .foregroundStyle(ColorToken.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("A sip adds its volume at once. Activity doubles the drain for one hour. Overlapping activity extends the window, it does not stack past twice.")
                        .font(TypeToken.caption)
                        .foregroundStyle(ColorToken.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("The stave sits at 30 percent of the daily goal. Falling through it writes an Ebb. Climbing back writes a Stem.")
                        .font(TypeToken.caption)
                        .foregroundStyle(ColorToken.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Text(level.side == .safe ? "Safe" : "Ebb")
                            .font(TypeToken.body)
                            .foregroundStyle(ColorToken.ink)
                        Spacer(minLength: SpaceToken.xs)
                        Text(AquiferFormat.millilitresLabeled(level.remainingMl))
                            .font(TypeToken.secondary)
                            .foregroundStyle(ColorToken.muted)
                            .monospacedDigit()
                    }
                    .padding(SpaceToken.sm)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))

                    Button("Close", action: close)
                        .buttonStyle(WellButtonStyle(kind: .primary))
                }
                .padding(SpaceToken.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(ColorToken.background.ignoresSafeArea())
            .navigationTitle("Ebb drain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close", action: close)
                }
            }
        }
    }
}
