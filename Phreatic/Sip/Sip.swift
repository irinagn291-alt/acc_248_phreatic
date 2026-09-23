import Foundation

/// One logged drink. Append-only event with a timestamp and a daykey so a
/// past day recomputes byte for byte from the file.
struct Sip: Identifiable, Hashable, Sendable, Codable, Equatable {
    let id: UUID
    let recordedAt: Date
    let dayKey: Int
    let volumeMl: Int

    init(id: UUID = UUID(), recordedAt: Date, dayKey: Int, volumeMl: Int) {
        self.id = id
        self.recordedAt = recordedAt
        self.dayKey = dayKey
        self.volumeMl = volumeMl
    }
}
