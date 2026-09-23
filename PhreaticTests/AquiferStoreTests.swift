import XCTest
@testable import Phreatic

@MainActor
final class AquiferStoreTests: XCTestCase {
    func test_primaryVerbEmptyPopulatedAndInvalid() {
        var ledger = RechargeLedger(dayKey: DayKey(rawValue: 20260920))
        XCTAssertNil(ledger.undoLastSip())
        XCTAssertNil(ledger.appendSip(volumeMl: 0, at: Date(timeIntervalSince1970: 1)))
        XCTAssertNil(ledger.appendSip(volumeMl: -40, at: Date(timeIntervalSince1970: 1)))
        let sip = ledger.appendSip(volumeMl: 250, at: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(sip?.volumeMl, 250)
        XCTAssertEqual(ledger.sips.count, 1)
        XCTAssertEqual(ledger.undoLastSip()?.volumeMl, 250)
        XCTAssertTrue(ledger.sips.isEmpty)
    }

    func test_roundTripWriteReload() async throws {
        let harness = try StoreHarness()
        await harness.store.load()
        harness.store.setIntake(WakeIntake(bodyKg: 72, wakeHour: 7, sleepHour: 23))
        let sip = harness.store.logSip(volumeMl: 250, at: harness.morning)
        XCTAssertEqual(sip?.volumeMl, 250)
        await harness.store.flush()

        let morning = harness.morning
        let reloaded = AquiferStore(
            directory: harness.directory,
            defaults: harness.defaults,
            calendar: harness.calendar,
            now: { morning }
        )
        await reloaded.load()
        let bodyKg = reloaded.file.bodyKg
        let firstSip = reloaded.file.days.values.first?.sips.first
        let labels = Mirror(reflecting: reloaded.file.days.values.first ?? DayRecord.fresh(wakeVolumeMl: 0))
            .children
            .compactMap(\.label)
        XCTAssertEqual(bodyKg, 72)
        XCTAssertEqual(firstSip?.volumeMl, 250)
        XCTAssertEqual(firstSip?.id, sip?.id)
        XCTAssertFalse(labels.contains("level"))
    }

    func test_corruptFileFallsBackThenEmpties() async throws {
        let harness = try StoreHarness()
        await harness.store.load()
        harness.store.logSip(volumeMl: 250, at: harness.morning)
        await harness.store.flush()

        let fileURL = harness.directory.appendingPathComponent("well.plist")
        try Data("not a plist".utf8).write(to: fileURL, options: .atomic)

        let morning = harness.morning
        let broken = AquiferStore(
            directory: harness.directory,
            defaults: harness.defaults,
            calendar: harness.calendar,
            now: { morning }
        )
        await broken.load()
        let recoveredVolume = broken.file.days.values.first?.sips.first?.volumeMl
        let recoveredNotice = broken.recoveryNotice
        XCTAssertEqual(recoveredVolume, 250)
        XCTAssertNotNil(recoveredNotice)

        try Data("still broken".utf8).write(to: fileURL, options: .atomic)
        try Data("still broken".utf8).write(
            to: harness.directory.appendingPathComponent("well.plist.bak"),
            options: .atomic
        )
        try Data("still broken".utf8).write(
            to: harness.directory.appendingPathComponent("well.plist.backup"),
            options: .atomic
        )
        let empty = AquiferStore(
            directory: harness.directory,
            defaults: harness.defaults,
            calendar: harness.calendar,
            now: { morning }
        )
        await empty.load()
        let emptyDays = empty.file.days
        let emptyNotice = empty.recoveryNotice
        XCTAssertTrue(emptyDays.isEmpty)
        XCTAssertNotNil(emptyNotice)
    }

    func test_resetAllDataClearsMemoryAndDisk() async throws {
        let harness = try StoreHarness()
        await harness.store.load()
        harness.store.markIntakeDone()
        harness.store.logSip(volumeMl: 250, at: harness.morning)
        await harness.store.flush()
        await harness.store.resetAllData()
        let clearedDays = harness.store.file.days
        let intakeDone = harness.store.isIntakeDone
        XCTAssertTrue(clearedDays.isEmpty)
        XCTAssertFalse(intakeDone)
        let morning = harness.morning
        let again = AquiferStore(
            directory: harness.directory,
            defaults: harness.defaults,
            calendar: harness.calendar,
            now: { morning }
        )
        await again.load()
        let reloadedDays = again.file.days
        XCTAssertTrue(reloadedDays.isEmpty)
    }

    func test_pastDayIsReadOnly() async throws {
        let harness = try StoreHarness()
        await harness.store.load()
        let yesterday = harness.morning.addingTimeInterval(-24 * 60 * 60)
        let sip = harness.store.logSip(volumeMl: 250, at: yesterday)
        let days = harness.store.file.days
        XCTAssertNil(sip)
        XCTAssertTrue(days.isEmpty)
    }

    func test_tickWritesEbbWhenTheTableFalls() async throws {
        let harness = try StoreHarness()
        await harness.store.load()
        harness.store.setIntake(WakeIntake(bodyKg: 70, wakeHour: 7, sleepHour: 23))
        harness.store.tick(at: harness.morning)
        let morningMarks = harness.store.file.days.values.first?.ebbMarks ?? []
        XCTAssertTrue(morningMarks.isEmpty)
        let late = harness.morning.addingTimeInterval(12 * 60 * 60)
        harness.store.tick(at: late)
        let lateMarks = harness.store.file.days.values.first?.ebbMarks ?? []
        XCTAssertEqual(lateMarks.count, 1)
    }
}

@MainActor
private struct StoreHarness {
    let directory: URL
    let defaults: UserDefaults
    var calendar: Calendar
    let morning: Date
    let store: AquiferStore

    init() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("phr-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let suite = "phr.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            throw StoreHarnessError.defaults
        }
        defaults.removePersistentDomain(forName: suite)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 20
        parts.hour = 10
        parts.minute = 30
        let morning = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        self.directory = directory
        self.defaults = defaults
        self.calendar = calendar
        self.morning = morning
        self.store = AquiferStore(
            directory: directory,
            defaults: defaults,
            calendar: calendar,
            now: { morning }
        )
    }
}

private enum StoreHarnessError: Error {
    case defaults
}
