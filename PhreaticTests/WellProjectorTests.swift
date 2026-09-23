import XCTest
@testable import Phreatic

final class WellProjectorTests: XCTestCase {
    func test_leftAloneTheWellEmptiesAtSleep() {
        let env = ProjectionEnv()
        let inputs = env.inputs(now: env.sleep, day: DayRecord.fresh(wakeVolumeMl: env.goal))
        let level = WellProjector.project(inputs)
        XCTAssertEqual(level.millilitres, 0, accuracy: 0.75)
        XCTAssertEqual(level.side, .ebb)
    }

    func test_sipRaisesTheWaterTable() {
        let env = ProjectionEnv()
        var day = DayRecord.fresh(wakeVolumeMl: env.goal)
        day.sips = [Sip(recordedAt: env.wake, dayKey: env.dayKey.rawValue, volumeMl: 250)]
        let atWake = WellProjector.project(env.inputs(now: env.wake, day: day))
        XCTAssertEqual(atWake.millilitres, Double(env.goal + 250), accuracy: 0.01)
    }

    func test_activityDoublesDrainWithoutStackingPastTwo() {
        let env = ProjectionEnv()
        let first = Activity(recordedAt: env.wake, dayKey: env.dayKey.rawValue)
        let overlap = Activity(
            recordedAt: env.wake.addingTimeInterval(30 * 60),
            dayKey: env.dayKey.rawValue
        )
        let hour = env.wake.addingTimeInterval(60 * 60)
        let ninety = env.wake.addingTimeInterval(90 * 60)
        let still = WellProjector.project(env.inputs(now: hour, day: DayRecord.fresh(wakeVolumeMl: env.goal)))
        var single = DayRecord.fresh(wakeVolumeMl: env.goal)
        single.activities = [first]
        let doubled = WellProjector.project(env.inputs(now: hour, day: single))
        var stacked = DayRecord.fresh(wakeVolumeMl: env.goal)
        stacked.activities = [first, overlap]
        let mergedHour = WellProjector.project(env.inputs(now: hour, day: stacked))
        let mergedNinety = WellProjector.project(env.inputs(now: ninety, day: stacked))

        let stillDrain = Double(env.goal) - still.millilitres
        let doubledDrain = Double(env.goal) - doubled.millilitres
        XCTAssertEqual(doubledDrain, stillDrain * 2, accuracy: 0.5)
        XCTAssertEqual(mergedHour.millilitres, doubled.millilitres, accuracy: 0.5)

        let ninetyDrain = Double(env.goal) - mergedNinety.millilitres
        XCTAssertEqual(ninetyDrain, stillDrain * 2 * 1.5, accuracy: 1.0)
    }

    func test_bodyCoefficientIsACeiling() {
        let env = ProjectionEnv()
        let minutes = DrawDown.wakingMinutes(wakeHour: 7, sleepHour: 23)
        let rate = DrawDown.baseRateMlPerMinute(bodyKg: 70, dailyGoalMl: env.goal, wakingMinutes: minutes)
        XCTAssertEqual(rate, Double(env.goal) / Double(minutes), accuracy: 0.0001)
        XCTAssertLessThan(rate, 70 * 0.4)
    }

    func test_projectionIsDeterministic() {
        let env = ProjectionEnv()
        var day = DayRecord.fresh(wakeVolumeMl: env.goal)
        day.sips = [Sip(recordedAt: env.wake.addingTimeInterval(120), dayKey: env.dayKey.rawValue, volumeMl: 250)]
        let now = env.wake.addingTimeInterval(3 * 60 * 60)
        let first = WellProjector.project(env.inputs(now: now, day: day))
        let second = WellProjector.project(env.inputs(now: now, day: day))
        XCTAssertEqual(first, second)
    }

    func test_wellLevelIsNeverStoredOnTheDayRecord() {
        let labels = Mirror(reflecting: DayRecord.fresh(wakeVolumeMl: 2300)).children.compactMap(\.label)
        XCTAssertFalse(labels.contains("level"))
        XCTAssertFalse(labels.contains("wellLevel"))
        XCTAssertFalse(labels.contains("millilitres"))
        XCTAssertTrue(labels.contains("wakeVolumeMl"))
        XCTAssertTrue(labels.contains("sips"))
    }
}

private struct ProjectionEnv {
    var calendar: Calendar
    let dayKey: DayKey
    let wake: Date
    let sleep: Date
    let goal: Int

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        self.calendar = calendar
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 20
        parts.hour = 0
        let start = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        dayKey = DayKey.from(start, calendar: calendar)
        wake = DrawDown.hourDate(dayStart: start, hour: 7, calendar: calendar)
        sleep = DrawDown.hourDate(dayStart: start, hour: 23, calendar: calendar)
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
