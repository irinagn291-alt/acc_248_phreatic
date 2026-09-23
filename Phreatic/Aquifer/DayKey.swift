import Foundation

/// Calendar day identity in YYYYMMDD form, built from startOfDay in the
/// keeper's current time zone. Keys the append-only day map on disk.
struct DayKey: RawRepresentable, Hashable, Sendable, Codable, Comparable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func from(_ date: Date, calendar: Calendar = .current) -> DayKey {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return DayKey(rawValue: year * 10_000 + month * 100 + day)
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    func startOfDay(calendar: Calendar = .current) -> Date {
        var parts = DateComponents()
        parts.year = rawValue / 10_000
        parts.month = (rawValue / 100) % 100
        parts.day = rawValue % 100
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
