import Foundation

/// Written when a sip lifts the water table back above the stave. Idempotent
/// with EbbMark: one mark per side, then wait for the next crossing.
struct StemMark: Identifiable, Hashable, Sendable, Codable, Equatable {
    let id: UUID
    let recordedAt: Date
    let dayKey: Int
    let levelMl: Double

    init(id: UUID = UUID(), recordedAt: Date, dayKey: Int, levelMl: Double) {
        self.id = id
        self.recordedAt = recordedAt
        self.dayKey = dayKey
        self.levelMl = levelMl
    }
}
