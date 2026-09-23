import CoreGraphics

/// Two radii only: 14 for cards and sheets, 6 for chips. Never a third, never zero.
enum RadiusToken {
    static let card: CGFloat = 14
    static let chip: CGFloat = 6
}
