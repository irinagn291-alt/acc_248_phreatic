import SwiftUI

/// Hero surface. Four Canvas passes: back wall, dithered water clipped to
/// the falling table, meniscus, front rim. Depth from offset and a soft
/// inner shadow, not a 3D scene. The only custom-rendered surface.
struct WellCanvas: View {
    let level: WellLevel
    let reduceMotion: Bool

    @ScaledMetric(relativeTo: .title) private var wellWidth: CGFloat = 220

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let fill = fillFraction
            Canvas { context, canvasSize in
                drawBackWall(context: context, size: canvasSize)
                drawWater(context: context, size: canvasSize, fill: fill)
                drawMeniscus(context: context, size: canvasSize, fill: fill)
                drawFrontRim(context: context, size: canvasSize)
            }
            .frame(width: size.width, height: size.height)
        }
        .frame(maxWidth: wellWidth * 1.4, maxHeight: .infinity)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: level.remainingMl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var fillFraction: CGFloat {
        let goal = max(1, level.dailyGoalMl)
        return CGFloat(min(1, max(0, level.millilitres / Double(goal))))
    }

    private var accessibilityLabel: String {
        let remaining = AquiferFormat.millilitres(level.remainingMl)
        let word = level.side == .safe ? "Safe" : "Ebb"
        return "Well, \(remaining) millilitres remaining, \(word)"
    }

    private func drawBackWall(context: GraphicsContext, size: CGSize) {
        let shaft = shaftRect(in: size)
        context.fill(
            Path(roundedRect: shaft, cornerRadius: RadiusToken.card, style: .continuous),
            with: .color(ColorToken.surface)
        )
        var shadow = context
        shadow.clipToLayer { layer in
            layer.fill(
                Path(roundedRect: shaft, cornerRadius: RadiusToken.card, style: .continuous),
                with: .color(ColorToken.background.opacity(0.55))
            )
        }
        shadow.fill(
            Path(roundedRect: shaft.insetBy(dx: SpaceToken.xs, dy: SpaceToken.xs), cornerRadius: RadiusToken.card, style: .continuous),
            with: .color(ColorToken.background.opacity(0.35))
        )
    }

    private func drawWater(context: GraphicsContext, size: CGSize, fill: CGFloat) {
        let shaft = shaftRect(in: size)
        let waterHeight = shaft.height * fill
        let water = CGRect(
            x: shaft.minX,
            y: shaft.maxY - waterHeight,
            width: shaft.width,
            height: waterHeight
        )
        guard waterHeight > 1 else { return }
        var clipped = context
        clipped.clip(to: Path(roundedRect: shaft, cornerRadius: RadiusToken.card, style: .continuous))
        let cell = SpaceToken.unit / 2
        let columns = Int(ceil(water.width / cell))
        let rows = Int(ceil(water.height / cell))
        for row in 0..<rows {
            for column in 0..<columns {
                let depth = rows <= 1 ? 1.0 : Double(row) / Double(rows - 1)
                let stepped = OrderedDither.quantize(value: 0.35 + depth * 0.45, x: column, y: row, levels: 4)
                let rect = CGRect(
                    x: water.minX + CGFloat(column) * cell,
                    y: water.minY + CGFloat(row) * cell,
                    width: cell,
                    height: cell
                )
                clipped.fill(Path(rect), with: .color(ColorToken.accent.opacity(0.28 + stepped * 0.45)))
            }
        }
        if !reduceMotion {
            var offset = context
            offset.translateBy(x: 0, y: 1)
            offset.clip(to: Path(roundedRect: shaft, cornerRadius: RadiusToken.card, style: .continuous))
            offset.fill(Path(water), with: .color(ColorToken.ink.opacity(0.04)))
        }
    }

    private func drawMeniscus(context: GraphicsContext, size: CGSize, fill: CGFloat) {
        let shaft = shaftRect(in: size)
        let y = shaft.maxY - shaft.height * fill
        guard fill > 0.02, fill < 0.98 else { return }
        let band = CGRect(x: shaft.minX + SpaceToken.xs, y: y - 3, width: shaft.width - SpaceToken.sm, height: 6)
        context.fill(Path(ellipseIn: band), with: .color(ColorToken.ink.opacity(0.22)))
    }

    private func drawFrontRim(context: GraphicsContext, size: CGSize) {
        let shaft = shaftRect(in: size)
        let rim = CGRect(x: shaft.minX - 4, y: shaft.minY - 6, width: shaft.width + 8, height: SpaceToken.sm)
        context.fill(
            Path(roundedRect: rim, cornerRadius: RadiusToken.chip, style: .continuous),
            with: .color(ColorToken.ink.opacity(0.18))
        )
        var inner = context
        inner.clip(to: Path(roundedRect: shaft, cornerRadius: RadiusToken.card, style: .continuous))
        let shade = CGRect(x: shaft.minX, y: shaft.minY, width: shaft.width, height: SpaceToken.sm)
        inner.fill(Path(shade), with: .color(ColorToken.background.opacity(0.28)))
    }

    private func shaftRect(in size: CGSize) -> CGRect {
        let width = min(size.width * 0.72, wellWidth)
        let height = size.height * 0.88
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }
}
