import Foundation

/// Shared locale formatters. Volumes and streak counts never use string
/// interpolation for the number itself.
enum AquiferFormat {
    static func millilitres(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "-"
    }

    static func millilitresLabeled(_ value: Int) -> String {
        "\(millilitres(value)) ml"
    }

    static func kilograms(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value.rounded())) ?? "-"
    }

    static func count(_ value: Int) -> String {
        millilitres(value)
    }

    static func clockHour(_ hour: Int) -> String {
        let clamped = WakeIntake.clampedHour(hour)
        var parts = DateComponents()
        parts.hour = clamped
        parts.minute = 0
        let calendar = Calendar.current
        let date = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func dayTitle(_ dayKey: DayKey, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: dayKey.startOfDay(calendar: calendar))
    }

    static func dayCardTitle(_ dayKey: DayKey, calendar: Calendar = .current, now: Date = Date()) -> String {
        let date = dayKey.startOfDay(calendar: calendar)
        let formatter = DateFormatter()
        formatter.locale = .current
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        formatter.setLocalizedDateFormatFromTemplate(sameYear ? "MMM d" : "MMM d yyyy")
        return formatter.string(from: date)
    }

    static func millilitresPerMinute(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: value)) ?? "-"
        return "\(number) ml per minute"
    }

    static func homeJobLine(remainingMl: Int) -> String {
        "\(millilitres(remainingMl)) ml left before you fall behind today. Log each sip to stay ahead."
    }

    static func holdSummary(held: Int, total: Int, todayHeld: Bool?) -> String {
        guard total > 0 else { return "No days logged yet." }
        let head = "\(count(held)) of the last \(count(total)) days held"
        guard let todayHeld else { return "\(head)." }
        if todayHeld {
            return "\(head). Today is still ahead."
        }
        return "\(head). Today is still ebbing."
    }

    static func timeOfDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func minutesUntilStave(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int((seconds / 60.0).rounded()))
        let number = count(minutes)
        if minutes == 1 {
            return "\(number) minute to the stave"
        }
        return "\(number) minutes to the stave"
    }

    static func staveHoldSentence(_ streak: Int) -> String {
        if streak <= 0 {
            return "The stave has not been held yet."
        }
        if streak == 1 {
            return "You have held the stave for 1 day."
        }
        return "You have held the stave for \(count(streak)) days."
    }
}
