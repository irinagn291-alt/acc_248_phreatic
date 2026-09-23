import XCTest
@testable import Phreatic

final class ReviewScreenKeyTests: XCTestCase {
    func test_readsOnceAfterIntake() {
        var consumed = false
        XCTAssertNil(
            ReviewScreenKey.consume(
                arguments: ["-ReviewScreen", "log"],
                intakeDone: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = ReviewScreenKey.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            intakeDone: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            ReviewScreenKey.consume(
                arguments: ["-ReviewScreen", "goals"],
                intakeDone: true,
                consumed: &consumed
            )
        )
    }

    func test_todayLogGoalsAndExtras() {
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "today"]), .today)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "well"]), .today)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "log"]), .log)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "history"]), .log)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "goals"]), .goals)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "settings"]), .goals)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "intake"]), .intake)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "ebb"]), .ebb)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "twist"]), .ebb)
        XCTAssertEqual(ReviewScreenKey.parse(["-ReviewScreen", "dial"]), .dial)
        XCTAssertNil(ReviewScreenKey.parse(["-ReviewScreen", "aura"]))
        XCTAssertNil(ReviewScreenKey.parse(["-SomethingElse", "log"]))
    }

    func test_unknownKeyStillConsumes() {
        var consumed = false
        XCTAssertNil(
            ReviewScreenKey.consume(
                arguments: ["-ReviewScreen", "aura"],
                intakeDone: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
    }

    func test_routerMapsKeysToSheets() {
        XCTAssertNil(RootRouter.sheet(for: .today))
        XCTAssertEqual(RootRouter.sheet(for: .log), .history)
        XCTAssertEqual(RootRouter.sheet(for: .goals), .settings)
        XCTAssertEqual(RootRouter.sheet(for: .ebb), .ebbDrain)
        XCTAssertEqual(RootRouter.sheet(for: .dial), .dial)
        XCTAssertTrue(RootRouter.opensIntake(.intake))
        XCTAssertFalse(RootRouter.opensIntake(.today))
    }
}
