import Foundation

/// Owns the drain rate. The body coefficient is a ceiling; the well reaches
/// empty at the sleep hour when left alone, not in the first hour.
enum DrawDown {
    static let bodyCoefficientMlPerKgPerMinute = 0.4
    static let activityMultiplier = 2.0

    static func wakingMinutes(wakeHour: Int, sleepHour: Int) -> Int {
        let wake = WakeIntake.clampedHour(wakeHour)
        let sleep = WakeIntake.clampedHour(sleepHour)
        if sleep > wake {
            return (sleep - wake) * 60
        }
        if sleep < wake {
            return (24 - wake + sleep) * 60
        }
        return 24 * 60
    }

    static func wakingInterval(
        dayStart: Date,
        wakeHour: Int,
        sleepHour: Int,
        calendar: Calendar
    ) -> DateInterval {
        let wake = hourDate(dayStart: dayStart, hour: wakeHour, calendar: calendar)
        var sleep = hourDate(dayStart: dayStart, hour: sleepHour, calendar: calendar)
        if sleep <= wake {
            sleep = calendar.date(byAdding: .day, value: 1, to: sleep) ?? sleep.addingTimeInterval(24 * 60 * 60)
        }
        return DateInterval(start: wake, end: sleep)
    }

    static func hourDate(dayStart: Date, hour: Int, calendar: Calendar) -> Date {
        let clamped = WakeIntake.clampedHour(hour)
        return calendar.date(bySettingHour: clamped, minute: 0, second: 0, of: dayStart)
            ?? dayStart.addingTimeInterval(TimeInterval(clamped * 3600))
    }

    static func baseRateMlPerMinute(bodyKg: Double, dailyGoalMl: Int, wakingMinutes: Int) -> Double {
        let minutes = max(1, wakingMinutes)
        let bodyCap = max(0, bodyKg) * bodyCoefficientMlPerKgPerMinute
        let evenDrain = Double(max(0, dailyGoalMl)) / Double(minutes)
        return min(bodyCap, evenDrain)
    }

    static func mergedActivityWindows(_ activities: [Activity]) -> [DateInterval] {
        let sorted = activities.map(\.interval).sorted { $0.start < $1.start }
        var merged: [DateInterval] = []
        for interval in sorted {
            guard let last = merged.last else {
                merged.append(interval)
                continue
            }
            if last.end >= interval.start {
                let end = max(last.end, interval.end)
                merged[merged.count - 1] = DateInterval(start: last.start, end: end)
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    static func accruedMl(
        from wake: Date,
        to now: Date,
        sleep: Date,
        baseRateMlPerMinute: Double,
        activities: [Activity]
    ) -> Double {
        let end = min(now, sleep)
        guard end > wake, baseRateMlPerMinute > 0 else { return 0 }
        let windows = mergedActivityWindows(activities)
        var points: [Date] = [wake, end]
        for window in windows {
            if window.start > wake && window.start < end {
                points.append(window.start)
            }
            if window.end > wake && window.end < end {
                points.append(window.end)
            }
        }
        points.sort()
        var total = 0.0
        for index in 0..<(points.count - 1) {
            let start = points[index]
            let finish = points[index + 1]
            guard finish > start else { continue }
            let mid = start.addingTimeInterval(finish.timeIntervalSince(start) / 2)
            let doubled = windows.contains { $0.contains(mid) }
            let rate = doubled ? baseRateMlPerMinute * activityMultiplier : baseRateMlPerMinute
            total += (finish.timeIntervalSince(start) / 60.0) * rate
        }
        return total
    }

    static func rateMlPerMinute(at date: Date, baseRateMlPerMinute: Double, activities: [Activity]) -> Double {
        let windows = mergedActivityWindows(activities)
        let doubled = windows.contains { $0.contains(date) }
        return doubled ? baseRateMlPerMinute * activityMultiplier : baseRateMlPerMinute
    }
}
