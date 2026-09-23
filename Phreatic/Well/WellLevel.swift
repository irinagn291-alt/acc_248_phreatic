import Foundation

/// Projected water table in millilitres. Computed on demand, never stored.
/// wake volume plus sips minus accrued draw-down.
struct WellLevel: Sendable, Equatable {
    let millilitres: Double
    let staveMillilitres: Double
    let side: StaveSide
    let dailyGoalMl: Int
    let currentRateMlPerMinute: Double
    let secondsToStave: TimeInterval?

    var remainingMl: Int {
        Int(millilitres.rounded())
    }

    static func clamped(_ value: Double) -> Double {
        value.isFinite ? max(0, value) : 0
    }
}
