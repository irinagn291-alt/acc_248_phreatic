import Foundation

/// First-launch intake: body mass and waking hours. Named IntakeEntry in the
/// family brief; aquifer lexicon calls it the wake intake that sizes the well.
struct WakeIntake: Sendable, Equatable, Codable {
    var bodyKg: Double
    var wakeHour: Int
    var sleepHour: Int

    static let fallback = WakeIntake(bodyKg: 70, wakeHour: 7, sleepHour: 23)

    var sanitized: WakeIntake {
        let kg = bodyKg.isFinite && bodyKg > 0 ? min(max(bodyKg, 20), 300) : Self.fallback.bodyKg
        return WakeIntake(
            bodyKg: kg,
            wakeHour: Self.clampedHour(wakeHour),
            sleepHour: Self.clampedHour(sleepHour)
        )
    }

    static func clampedHour(_ hour: Int) -> Int {
        let wrapped = ((hour % 24) + 24) % 24
        return wrapped
    }
}
