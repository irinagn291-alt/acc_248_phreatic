import SwiftUI

/// At most six SF Pro steps. Numbers always take monospaced digits.
enum TypeToken {
    static func display(size: CGFloat = 56) -> Font {
        .system(size: size, weight: .semibold).monospacedDigit()
    }

    static let display: Font = .system(size: 56, weight: .semibold).monospacedDigit()
    static let title: Font = .title3.weight(.semibold)
    static let body: Font = .system(size: 17)
    static let secondary: Font = .subheadline.monospacedDigit()
    static let caption: Font = .footnote
    static let unit: Font = .footnote
}
