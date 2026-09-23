import SwiftUI
import UIKit

/// One typed colour accessor. Hex lives here and in the named coloursets.
/// Views read these names, never a raw hex literal.
enum ColorToken {
    static let background = resolved(name: "background", hex: "#483C28")
    static let surface = resolved(name: "surface", hex: "#574C38")
    static let ink = resolved(name: "ink", hex: "#F6F5F4")
    static let accent = resolved(name: "accent", hex: "#F2BC5F")
    static let muted = resolved(name: "muted", hex: "#C3BEB6")

    private static func resolved(name: String, hex: String) -> Color {
        if let named = UIColor(named: name) {
            return Color(uiColor: named)
        }
        return Color(wellHex: hex)
    }
}

private extension Color {
    init(wellHex hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
