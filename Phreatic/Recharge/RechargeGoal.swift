import Foundation

/// Daily recharge target in millilitres. Named HydrationGoal in the family
/// brief; aquifer lexicon treats it as the wake volume that fills the well.
struct RechargeGoal: Sendable, Equatable {
    let millilitres: Int
    let weightKg: Double
    let activityBonusMl: Int

    init(weightKg: Double, activityBonusMl: Int) {
        self.weightKg = weightKg
        self.activityBonusMl = DrawBonus.snapped(activityBonusMl).rawValue
        self.millilitres = RechargeMath.goalMl(weightKg: weightKg, activityBonusMl: self.activityBonusMl)
    }
}
