import Foundation

/// A day with zero EbbMarks after wake is a stave-hold. History streak is
/// the run of holds ending at the most recent complete or current day.
enum StaveHold {
    static func isHold(_ record: DayRecord) -> Bool {
        record.ebbMarks.isEmpty
    }

    static func streak(
        days: [Int: DayRecord],
        through dayKey: DayKey,
        calendar: Calendar = .current
    ) -> Int {
        guard !days.isEmpty else { return 0 }
        var count = 0
        var cursor = dayKey.rawValue
        while let record = days[cursor] {
            guard isHold(record) else { break }
            count += 1
            guard let previous = previousDayKey(cursor, calendar: calendar) else { break }
            cursor = previous
        }
        return count
    }

    static func previousDayKey(_ raw: Int, calendar: Calendar) -> Int? {
        let year = raw / 10_000
        let month = (raw / 100) % 100
        let day = raw % 100
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        guard let date = calendar.date(from: parts),
              let previous = calendar.date(byAdding: .day, value: -1, to: date)
        else {
            return nil
        }
        return DayKey.from(previous, calendar: calendar).rawValue
    }
}
