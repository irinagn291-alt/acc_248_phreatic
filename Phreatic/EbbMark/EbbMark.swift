import Foundation

/// Written when the water table falls through the stave. Idempotent: the
/// projector refuses a second mark while the well is already on the ebb side.
struct EbbMark: Identifiable, Hashable, Sendable, Codable, Equatable {
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
