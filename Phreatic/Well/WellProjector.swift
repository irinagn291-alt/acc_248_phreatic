import Foundation

/// Continuous-drain projection. There is no three-state fold and no reducer
/// enum: Recharge owns the goal, DrawDown owns the rate, Stave owns the
/// partition, and the view reads one WellLevel struct.
enum WellProjector {
    struct Inputs: Sendable, Equatable {
        var bodyKg: Double
        var wakeHour: Int
        var sleepHour: Int
        var dailyGoalMl: Int
        var day: DayRecord
        var dayKey: DayKey
        var now: Date
        var calendar: Calendar
    }

    static func project(_ inputs: Inputs) -> WellLevel {
        let dayStart = inputs.dayKey.startOfDay(calendar: inputs.calendar)
        let waking = DrawDown.wakingInterval(
            dayStart: dayStart,
            wakeHour: inputs.wakeHour,
            sleepHour: inputs.sleepHour,
            calendar: inputs.calendar
        )
        let minutes = max(1, Int((waking.duration / 60.0).rounded(.down)))
        let baseRate = DrawDown.baseRateMlPerMinute(
            bodyKg: inputs.bodyKg,
            dailyGoalMl: inputs.dailyGoalMl,
            wakingMinutes: minutes
        )
        let sipTotal = inputs.day.sips
            .filter { $0.recordedAt <= inputs.now }
            .reduce(0) { $0 + $1.volumeMl }
        let drain = DrawDown.accruedMl(
            from: waking.start,
            to: inputs.now,
            sleep: waking.end,
            baseRateMlPerMinute: baseRate,
            activities: inputs.day.activities.filter { $0.recordedAt <= inputs.now }
        )
        let raw = Double(inputs.day.wakeVolumeMl) + Double(sipTotal) - drain
        let millilitres = WellLevel.clamped(raw)
        let stave = Stave.thresholdMl(dailyGoalMl: inputs.dailyGoalMl)
        let side = Stave.side(levelMl: millilitres, dailyGoalMl: inputs.dailyGoalMl)
        let rate = DrawDown.rateMlPerMinute(
            at: min(max(inputs.now, waking.start), waking.end),
            baseRateMlPerMinute: baseRate,
            activities: inputs.day.activities
        )
        let secondsToStave: TimeInterval?
        if side == .safe, rate > 0, millilitres > stave {
            secondsToStave = ((millilitres - stave) / rate) * 60.0
        } else {
            secondsToStave = nil
        }
        return WellLevel(
            millilitres: millilitres,
            staveMillilitres: stave,
            side: side,
            dailyGoalMl: inputs.dailyGoalMl,
            currentRateMlPerMinute: rate,
            secondsToStave: secondsToStave
        )
    }

    static func recordedSide(of day: DayRecord) -> StaveSide {
        let lastEbb = day.ebbMarks.max(by: { $0.recordedAt < $1.recordedAt })
        let lastStem = day.stemMarks.max(by: { $0.recordedAt < $1.recordedAt })
        switch (lastEbb, lastStem) {
        case (nil, nil):
            return .safe
        case (_?, nil):
            return .ebb
        case (nil, _):
            return .safe
        case (let ebb?, let stem?):
            return ebb.recordedAt >= stem.recordedAt ? .ebb : .safe
        }
    }

    static func crossing(for inputs: Inputs, projected: WellLevel) -> StaveCrossing.Mark? {
        StaveCrossing.mark(
            recordedSide: recordedSide(of: inputs.day),
            projectedSide: projected.side,
            at: inputs.now,
            dayKey: inputs.dayKey,
            levelMl: projected.millilitres
        )
    }
}
