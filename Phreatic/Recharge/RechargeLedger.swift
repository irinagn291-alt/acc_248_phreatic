import Foundation

/// Append-only Sip and Activity events for one daykey. Undo removes the last
/// sip of the current day and nothing else. Past days stay read-only.
struct RechargeLedger: Sendable, Equatable {
    var dayKey: DayKey
    var sips: [Sip]
    var activities: [Activity]

    init(dayKey: DayKey, sips: [Sip] = [], activities: [Activity] = []) {
        self.dayKey = dayKey
        self.sips = sips
        self.activities = activities
    }

    mutating func appendSip(volumeMl: Int, at date: Date) -> Sip? {
        guard SipVolume.isValid(volumeMl) else { return nil }
        let sip = Sip(recordedAt: date, dayKey: dayKey.rawValue, volumeMl: volumeMl)
        sips.append(sip)
        return sip
    }

    mutating func undoLastSip() -> Sip? {
        guard let last = sips.popLast() else { return nil }
        return last
    }

    mutating func appendActivity(at date: Date) -> Activity {
        let activity = Activity(recordedAt: date, dayKey: dayKey.rawValue)
        activities.append(activity)
        return activity
    }
}
