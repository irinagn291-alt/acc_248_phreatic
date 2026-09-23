import UIKit

/// One haptic on a successful commit. Sheets and navigation stay silent.
/// CoreHaptics is available on device; the light impact is the same pulse
/// without a shared engine.
enum WellHaptics {
    @MainActor
    static func commit() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}
