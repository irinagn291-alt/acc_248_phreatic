import SwiftUI

/// Falling wax cap. Shape itself reads as ebb so colour is never the only signal.
struct EbbSealView: View {
    var body: some View {
        ZStack {
            Image("phr_EbbSeal")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .clipped()
            EbbSealShape()
                .fill(ColorToken.muted.opacity(0.18))
                .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }
}

struct EbbSealShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        path.addEllipse(in: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08))
        path.move(to: CGPoint(x: midX - rect.width * 0.22, y: rect.height * 0.38))
        path.addLine(to: CGPoint(x: midX, y: rect.height * 0.68))
        path.addLine(to: CGPoint(x: midX + rect.width * 0.22, y: rect.height * 0.38))
        return path
    }
}
