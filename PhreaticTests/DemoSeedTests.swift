import XCTest
@testable import Phreatic

final class DemoSeedTests: XCTestCase {
    func test_seedLandsAPriorSipSoTheHomeVerbCanStem() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 20
        parts.hour = 10
        parts.minute = 30
        let now = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        let file = DemoSeed.makeFile(now: now, calendar: calendar)
        let today = DayKey.from(now, calendar: calendar)
        let record = file.days[today.rawValue]
        XCTAssertEqual(file.sipVolumeMl, SipVolume.defaultMl)
        XCTAssertEqual(record?.sips.count, 1)
        XCTAssertEqual(record?.sips.first?.volumeMl, SipVolume.defaultMl)
        XCTAssertEqual(record?.ebbMarks.count, 1)
        XCTAssertEqual(record?.stemMarks.count, 1)
        XCTAssertGreaterThan(file.days.count, 4)
        XCTAssertTrue(file.days.values.contains { $0.ebbMarks.isEmpty && !$0.sips.isEmpty })
    }
}
