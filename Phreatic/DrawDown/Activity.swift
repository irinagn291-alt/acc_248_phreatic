import Foundation

/// A logged exertion. Doubles drain for 60 minutes from recordedAt.
/// Overlapping windows do not stack past 2x; they extend the span.
struct Activity: Identifiable, Hashable, Sendable, Codable, Equatable {
    let id: UUID
    let recordedAt: Date
    let dayKey: Int
    let durationMinutes: Int

    static let windowMinutes = 60

    init(
        id: UUID = UUID(),
        recordedAt: Date,
        dayKey: Int,
        durationMinutes: Int = Activity.windowMinutes
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.dayKey = dayKey
        self.durationMinutes = max(1, durationMinutes)
    }

    var interval: DateInterval {
        DateInterval(start: recordedAt, duration: TimeInterval(durationMinutes * 60))
    }
}
