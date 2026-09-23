import XCTest
@testable import Phreatic

final class DayKeyTests: XCTestCase {
    func test_fromDateUsesStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 20
        parts.hour = 15
        parts.minute = 40
        guard let date = calendar.date(from: parts) else {
            XCTFail("expected a constructed date")
            return
        }
        XCTAssertEqual(DayKey.from(date, calendar: calendar).rawValue, 20260920)
    }

    func test_startOfDayRoundTrip() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let key = DayKey(rawValue: 20260920)
        let start = key.startOfDay(calendar: calendar)
        XCTAssertEqual(DayKey.from(start, calendar: calendar), key)
        XCTAssertEqual(calendar.component(.hour, from: start), 0)
    }

    func test_ordering() {
        XCTAssertTrue(DayKey(rawValue: 20260919) < DayKey(rawValue: 20260920))
    }
}
