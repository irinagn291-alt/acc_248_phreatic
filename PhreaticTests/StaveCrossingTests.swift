import XCTest
@testable import Phreatic

final class StaveCrossingTests: XCTestCase {
    func test_fallingThroughTheStaveWritesEbbMark() {
        let env = CrossingEnv()
        var day = DayRecord.fresh(wakeVolumeMl: env.goal)
        let atEbb = env.wake.addingTimeInterval(12 * 60 * 60)
        var inputs = env.inputs(now: atEbb, day: day)
        let projected = WellProjector.project(inputs)
        XCTAssertEqual(projected.side, .ebb)
        let mark = WellProjector.crossing(for: inputs, projected: projected)
        guard case .ebb(let ebb) = mark else {
            XCTFail("expected an ebb mark")
            return
        }
        XCTAssertEqual(ebb.dayKey, env.dayKey.rawValue)
        day.ebbMarks.append(ebb)
        inputs.day = day
        XCTAssertNil(WellProjector.crossing(for: inputs, projected: projected))
    }

    func test_sipBackAboveTheStaveWritesStemMark() {
        let env = CrossingEnv()
        var day = DayRecord.fresh(wakeVolumeMl: env.goal)
        let atEbb = env.wake.addingTimeInterval(12 * 60 * 60)
        var inputs = env.inputs(now: atEbb, day: day)
        let ebbLevel = WellProjector.project(inputs)
        guard case .ebb(let ebb) = WellProjector.crossing(for: inputs, projected: ebbLevel) else {
            XCTFail("expected an ebb mark first")
            return
        }
        day.ebbMarks.append(ebb)
        day.sips.append(Sip(recordedAt: atEbb, dayKey: env.dayKey.rawValue, volumeMl: 2000))
        inputs.day = day
        let recovered = WellProjector.project(inputs)
        XCTAssertEqual(recovered.side, .safe)
        guard case .stem = WellProjector.crossing(for: inputs, projected: recovered) else {
            XCTFail("expected a stem mark")
            return
        }
    }

    func test_duplicateSideIsRefused() {
        let mark = StaveCrossing.mark(
            recordedSide: .ebb,
            projectedSide: .ebb,
            at: Date(timeIntervalSince1970: 0),
            dayKey: DayKey(rawValue: 20260920),
            levelMl: 100
        )
        XCTAssertNil(mark)
    }

    func test_staveHoldIgnoresDaysWithEbbMarks() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let today = DayKey(rawValue: 20260920)
        let yesterday = DayKey(rawValue: 20260919)
        var hold = DayRecord.fresh(wakeVolumeMl: 2300)
        var broken = DayRecord.fresh(wakeVolumeMl: 2300)
        broken.ebbMarks = [
            EbbMark(recordedAt: Date(timeIntervalSince1970: 1), dayKey: yesterday.rawValue, levelMl: 100)
        ]
        let streak = StaveHold.streak(
            days: [today.rawValue: hold, yesterday.rawValue: broken],
            through: today,
            calendar: calendar
        )
        XCTAssertEqual(streak, 1)
        hold.ebbMarks = [
            EbbMark(recordedAt: Date(timeIntervalSince1970: 2), dayKey: today.rawValue, levelMl: 80)
        ]
        XCTAssertFalse(StaveHold.isHold(hold))
    }
}

private struct CrossingEnv {
    var calendar: Calendar
    let dayKey: DayKey
    let wake: Date
    let goal: Int

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        self.calendar = calendar
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 20
        let start = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        dayKey = DayKey.from(start, calendar: calendar)
        wake = DrawDown.hourDate(dayStart: start, hour: 7, calendar: calendar)
        goal = RechargeMath.goalMl(weightKg: 70, activityBonusMl: 0)
    }

    func inputs(now: Date, day: DayRecord) -> WellProjector.Inputs {
        WellProjector.Inputs(
            bodyKg: 70,
            wakeHour: 7,
            sleepHour: 23,
            dailyGoalMl: goal,
            day: day,
            dayKey: dayKey,
            now: now,
            calendar: calendar
        )
    }
}
