import Foundation

/// Owns the family goal formula alone so it can be unit tested without a store.
/// goal = clamp(round50(weightKg * 33 + activityBonus), 1200, 5000).
enum RechargeMath {
    static let millilitresPerKilogram = 33.0
    static let minimumGoalMl = 1200
    static let maximumGoalMl = 5000
    static let roundStepMl = 50

    static func goalMl(weightKg: Double, activityBonusMl: Int) -> Int {
        let kg = weightKg.isFinite && weightKg > 0 ? weightKg : WakeIntake.fallback.bodyKg
        let bonus = DrawBonus.snapped(activityBonusMl).rawValue
        let raw = kg * millilitresPerKilogram + Double(bonus)
        let rounded = roundToStep(raw, step: Double(roundStepMl))
        let clamped = min(Double(maximumGoalMl), max(Double(minimumGoalMl), rounded))
        return Int(clamped)
    }

    static func roundToStep(_ value: Double, step: Double) -> Double {
        guard step > 0, value.isFinite else { return 0 }
        return (value / step).rounded() * step
    }
}

/// Activity bonus tiers that feed RechargeMath. Still water, a stirred day,
/// or a doubled draw. Values are millilitres added to the daily goal.
enum DrawBonus: Int, CaseIterable, Sendable, Codable {
    case still = 0
    case stirred = 350
    case doubled = 700

    static func snapped(_ millilitres: Int) -> DrawBonus {
        let allowed = DrawBonus.allCases
        return allowed.min(by: { abs($0.rawValue - millilitres) < abs($1.rawValue - millilitres) }) ?? .still
    }
}
