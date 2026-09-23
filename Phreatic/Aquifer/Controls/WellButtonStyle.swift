import SwiftUI

/// Primary, secondary, and destructive fills. Defines default, pressed,
/// disabled, and a brief committed state. Accent is reserved for the live verb.
struct WellButtonStyle: ButtonStyle {
    enum Kind: Equatable, Sendable {
        case primary
        case secondary
        case destructive
    }

    var kind: Kind = .primary
    var committed: Bool = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeToken.body.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: SpaceToken.unit * 6)
            .padding(.horizontal, SpaceToken.sm)
            .background(fill(isPressed: configuration.isPressed), in: shape)
            .overlay {
                if kind != .primary {
                    shape.strokeBorder(stroke, lineWidth: 1)
                }
            }
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(scale(isPressed: configuration.isPressed))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: committed)
            .contentShape(shape)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous)
    }

    private var foreground: Color {
        switch kind {
        case .primary:
            return ColorToken.background
        case .secondary, .destructive:
            return ColorToken.ink
        }
    }

    private var stroke: Color {
        kind == .destructive ? ColorToken.ink.opacity(0.55) : ColorToken.muted
    }

    private func fill(isPressed: Bool) -> Color {
        if committed, kind == .primary {
            return ColorToken.accent.opacity(0.72)
        }
        switch kind {
        case .primary:
            return isPressed ? ColorToken.accent.opacity(0.82) : ColorToken.accent
        case .secondary:
            return isPressed ? ColorToken.surface.opacity(0.7) : ColorToken.surface
        case .destructive:
            return isPressed ? ColorToken.surface.opacity(0.55) : ColorToken.surface
        }
    }

    private func scale(isPressed: Bool) -> CGFloat {
        if reduceMotion { return 1 }
        return isPressed ? 0.97 : 1
    }
}
