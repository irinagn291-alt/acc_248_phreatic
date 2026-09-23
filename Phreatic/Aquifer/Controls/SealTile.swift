import SwiftUI

/// One cap in the home or history grid. Shape plus a word, never colour alone.
struct SealTile: View {
    let title: String
    let caption: String
    let held: Bool
    let selected: Bool
    var action: () -> Void

    @ScaledMetric(relativeTo: .body) private var edge: CGFloat = 72

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: SpaceToken.xs) {
                Group {
                    if held {
                        StemSealView()
                    } else {
                        EbbSealView()
                    }
                }
                .frame(width: edge, height: edge)
                .frame(maxWidth: .infinity)

                Text(title)
                    .font(TypeToken.body)
                    .foregroundStyle(ColorToken.ink)
                    .lineLimit(1)

                Text(caption)
                    .font(TypeToken.secondary)
                    .foregroundStyle(ColorToken.muted)
                    .monospacedDigit()
                    .lineLimit(2)
            }
            .padding(SpaceToken.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous)
                    .strokeBorder(selected ? ColorToken.accent : Color.clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        "\(title), \(caption)"
    }
}
