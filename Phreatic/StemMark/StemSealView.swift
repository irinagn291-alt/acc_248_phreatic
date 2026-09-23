import SwiftUI

/// Rising wax cap. Distinct silhouette from the ebb seal so shape carries Safe.
struct StemSealView: View {
    var body: some View {
        ZStack {
            Image("phr_StemSeal")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .clipped()
            StemSealShape()
                .fill(ColorToken.accent.opacity(0.22))
                .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }
}

struct StemSealShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08))
        let midX = rect.midX
        path.move(to: CGPoint(x: midX - rect.width * 0.22, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: midX - rect.width * 0.08, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: midX - rect.width * 0.08, y: rect.height * 0.42))
        path.addLine(to: CGPoint(x: midX + rect.width * 0.08, y: rect.height * 0.42))
        path.addLine(to: CGPoint(x: midX + rect.width * 0.08, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: midX + rect.width * 0.22, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: midX, y: rect.height * 0.32))
        path.closeSubpath()
        return path
    }
}
