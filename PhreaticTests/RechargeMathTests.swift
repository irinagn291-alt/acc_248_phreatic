import XCTest
@testable import Phreatic

final class RechargeMathTests: XCTestCase {
    func test_familyInvariant_clampsAndRoundsToFifty() {
        XCTAssertEqual(RechargeMath.goalMl(weightKg: 70, activityBonusMl: 0), 2300)
        XCTAssertEqual(RechargeMath.goalMl(weightKg: 60, activityBonusMl: 350), 2350)
        XCTAssertEqual(RechargeMath.goalMl(weightKg: 30, activityBonusMl: 0), 1200)
        XCTAssertEqual(RechargeMath.goalMl(weightKg: 200, activityBonusMl: 700), 5000)
        XCTAssertEqual(RechargeMath.goalMl(weightKg: 40, activityBonusMl: 0), 1300)
    }

    func test_familyInvariant_bonusTiersAndDefaultTap() {
        XCTAssertEqual(DrawBonus.allCases.map(\.rawValue), [0, 350, 700])
        XCTAssertEqual(SipVolume.defaultMl, 250)
        XCTAssertEqual(DrawBonus.snapped(200), .stirred)
        XCTAssertEqual(DrawBonus.snapped(10), .still)
        XCTAssertEqual(DrawBonus.snapped(800), .doubled)
    }

    func test_rechargeGoal_matchesMath() {
        let goal = RechargeGoal(weightKg: 70, activityBonusMl: 0)
        XCTAssertEqual(goal.millilitres, 2300)
        XCTAssertEqual(goal.activityBonusMl, 0)
    }

    func test_invalidWeightFallsBack() {
        XCTAssertEqual(
            RechargeMath.goalMl(weightKg: -8, activityBonusMl: 0),
            RechargeMath.goalMl(weightKg: WakeIntake.fallback.bodyKg, activityBonusMl: 0)
        )
    }
}
