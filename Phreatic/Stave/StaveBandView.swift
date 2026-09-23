import SwiftUI

/// The 30 percent threshold and the control that opens History. Hairline
/// plus a label plate so type never sits on the water raster. Words only:
/// a sprite here reads as a dash at native size.
struct StaveBandView: View {
    let side: StaveSide
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(ColorToken.muted)
                    .frame(height: SpaceToken.hairline)
                HStack(spacing: SpaceToken.xs) {
                    Text(side == .safe ? "Still ahead" : "Behind")
                        .font(TypeToken.body.weight(.semibold))
                        .foregroundStyle(ColorToken.ink)
                    Text("Open history")
                        .font(TypeToken.body)
                        .foregroundStyle(ColorToken.ink)
                }
                .padding(.horizontal, SpaceToken.sm)
                .padding(.vertical, SpaceToken.xs)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: RadiusToken.chip, style: .continuous))
            }
            .frame(maxWidth: .infinity, minHeight: SpaceToken.unit * 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(side == .safe ? "Still ahead. Open history." : "Behind today. Open history.")
        .accessibilityHint("Opens the history of stave holds.")
    }
}
