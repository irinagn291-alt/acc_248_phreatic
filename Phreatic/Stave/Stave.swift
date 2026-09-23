import Foundation

/// The 30 percent threshold that partitions Safe from Ebb. Colour is never
/// the only signal; callers pair this side with a word and a seal shape.
enum StaveSide: String, Sendable, Codable, Equatable {
    case safe
    case ebb
}

enum Stave {
    static let fraction = 0.30

    static func thresholdMl(dailyGoalMl: Int) -> Double {
        Double(max(0, dailyGoalMl)) * fraction
    }

    static func side(levelMl: Double, dailyGoalMl: Int) -> StaveSide {
        levelMl >= thresholdMl(dailyGoalMl: dailyGoalMl) ? .safe : .ebb
    }
}

/// Crossing detector. Refuses a mark that duplicates the current side so
/// ticks and relaunches stay idempotent.
enum StaveCrossing {
    enum Mark: Equatable, Sendable {
        case ebb(EbbMark)
        case stem(StemMark)
    }

    static func mark(
        recordedSide: StaveSide,
        projectedSide: StaveSide,
        at date: Date,
        dayKey: DayKey,
        levelMl: Double
    ) -> Mark? {
        guard recordedSide != projectedSide else { return nil }
        switch projectedSide {
        case .ebb:
            return .ebb(EbbMark(recordedAt: date, dayKey: dayKey.rawValue, levelMl: levelMl))
        case .safe:
            return .stem(StemMark(recordedAt: date, dayKey: dayKey.rawValue, levelMl: levelMl))
        }
    }
}
