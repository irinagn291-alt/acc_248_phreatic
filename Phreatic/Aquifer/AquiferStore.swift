import Foundation
import Combine

/// One seam between domain logic and storage. In-memory AquiferFile is the
/// source of truth; the plist is a projection. UI never touches the file types.
@MainActor
final class AquiferStore: ObservableObject {
    static let demoFlagKey = AquiferFlag.demo
    static let intakeFlagKey = AquiferFlag.intake
    static let relativeFilePath = "phr/well.plist"

    @Published private(set) var file: AquiferFile
    @Published private(set) var recoveryNotice: String?

    private let io: AquiferFileIO
    private let defaults: UserDefaults
    private let fileURL: URL
    private let backupURL: URL
    private let bakURL: URL
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private var writeTask: Task<Void, Never>?
    private var flushTask: Task<Void, Never>?
    private let encoder: PropertyListEncoder
    private let decoder: PropertyListDecoder

    init(
        directory: URL,
        defaults: UserDefaults = .standard,
        io: AquiferFileIO = AquiferFileIO(),
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.io = io
        self.defaults = defaults
        self.fileURL = directory.appendingPathComponent("well.plist")
        self.backupURL = directory.appendingPathComponent("well.plist.backup")
        self.bakURL = directory.appendingPathComponent("well.plist.bak")
        self.calendar = calendar
        self.now = now
        self.file = .empty
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        self.encoder = encoder
        self.decoder = PropertyListDecoder()
    }

    static func applicationSupportDirectory() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("phr", isDirectory: true)
    }

    var isIntakeDone: Bool {
        defaults.bool(forKey: Self.intakeFlagKey)
    }

    var isDemoSeeded: Bool {
        defaults.bool(forKey: Self.demoFlagKey)
    }

    func markIntakeDone() {
        defaults.set(true, forKey: Self.intakeFlagKey)
    }

    func markDemoSeeded() {
        defaults.set(true, forKey: Self.demoFlagKey)
    }

    func load() async {
        do {
            if let data = try await io.data(at: fileURL) {
                if let decoded = decodeDocument(data) {
                    if decoded.schemaVersion != AquiferFile.currentSchemaVersion {
                        try await io.copy(fileURL, to: bakURL)
                    }
                    file = migrate(decoded)
                    recoveryNotice = nil
                    if decoded.schemaVersion != AquiferFile.currentSchemaVersion {
                        scheduleWrite()
                    }
                    return
                }
                let bakData = try await io.data(at: bakURL)
                let fallbackData = try await io.data(at: backupURL)
                let backupData = bakData ?? fallbackData
                if let backupData, let decoded = decodeDocument(backupData) {
                    file = migrate(decoded)
                    recoveryNotice = "The well file was restored from a backup copy."
                    scheduleWrite()
                    return
                }
                file = .empty
                recoveryNotice = "The well file could not be read. Today starts empty."
                return
            }
            file = .empty
            recoveryNotice = nil
        } catch {
            file = .empty
            recoveryNotice = "The well file could not be read. Today starts empty."
        }
    }

    func setIntake(_ intake: WakeIntake) {
        file.apply(intake)
        scheduleWrite()
    }

    func setActivityBonus(_ millilitres: Int) {
        file.activityBonusMl = DrawBonus.snapped(millilitres).rawValue
        scheduleWrite()
    }

    func setSipVolume(_ millilitres: Int) {
        file.sipVolumeMl = SipVolume.sanitized(millilitres)
        scheduleWrite()
    }

    @discardableResult
    func logSip(volumeMl: Int? = nil, at date: Date? = nil) -> Sip? {
        let stamp = date ?? now()
        let today = DayKey.from(stamp, calendar: calendar)
        guard canMutate(today, at: stamp) else { return nil }
        ensureDay(today)
        let volume = volumeMl ?? file.sipVolumeMl
        guard var record = file.days[today.rawValue] else { return nil }
        var ledger = RechargeLedger(dayKey: today, sips: record.sips, activities: record.activities)
        guard let sip = ledger.appendSip(volumeMl: volume, at: stamp) else { return nil }
        record.sips = ledger.sips
        file.days[today.rawValue] = record
        applyCrossing(dayKey: today, at: stamp)
        scheduleWrite()
        return sip
    }

    @discardableResult
    func logActivity(at date: Date? = nil) -> Activity? {
        let stamp = date ?? now()
        let today = DayKey.from(stamp, calendar: calendar)
        guard canMutate(today, at: stamp) else { return nil }
        ensureDay(today)
        guard var record = file.days[today.rawValue] else { return nil }
        var ledger = RechargeLedger(dayKey: today, sips: record.sips, activities: record.activities)
        let activity = ledger.appendActivity(at: stamp)
        record.activities = ledger.activities
        file.days[today.rawValue] = record
        applyCrossing(dayKey: today, at: stamp)
        scheduleWrite()
        return activity
    }

    @discardableResult
    func undoLastSip(at date: Date? = nil) -> Sip? {
        let stamp = date ?? now()
        let today = DayKey.from(stamp, calendar: calendar)
        guard canMutate(today, at: stamp) else { return nil }
        guard var record = file.days[today.rawValue] else { return nil }
        var ledger = RechargeLedger(dayKey: today, sips: record.sips, activities: record.activities)
        guard let sip = ledger.undoLastSip() else { return nil }
        record.sips = ledger.sips
        file.days[today.rawValue] = record
        applyCrossing(dayKey: today, at: stamp)
        requestImmediateFlush()
        return sip
    }

    func clearToday(at date: Date? = nil) {
        let stamp = date ?? now()
        let today = DayKey.from(stamp, calendar: calendar)
        guard canMutate(today, at: stamp) else { return }
        let goal = file.goal.millilitres
        file.days[today.rawValue] = DayRecord.fresh(wakeVolumeMl: goal)
        requestImmediateFlush()
    }

    func resetAllData() async {
        writeTask?.cancel()
        file = .empty
        recoveryNotice = nil
        defaults.removeObject(forKey: Self.intakeFlagKey)
        do {
            try await io.removeItem(at: fileURL)
            try await io.removeItem(at: backupURL)
            try await io.removeItem(at: bakURL)
        } catch {
            recoveryNotice = "The well file could not be cleared from disk."
        }
        await flush()
    }

    func project(at date: Date? = nil) -> WellLevel {
        let stamp = date ?? now()
        let today = DayKey.from(stamp, calendar: calendar)
        ensureDay(today)
        return WellProjector.project(inputs(dayKey: today, at: stamp))
    }

    func tick(at date: Date? = nil) {
        let stamp = date ?? now()
        let today = DayKey.from(stamp, calendar: calendar)
        ensureDay(today)
        applyCrossing(dayKey: today, at: stamp)
        scheduleWrite()
    }

    func staveHoldStreak(at date: Date? = nil) -> Int {
        let stamp = date ?? now()
        return StaveHold.streak(days: file.days, through: DayKey.from(stamp, calendar: calendar), calendar: calendar)
    }

    func handleScenePhase(isActive: Bool) async {
        if !isActive {
            writeTask?.cancel()
            await flush()
        }
    }

    func flush() async {
        do {
            try await persist(file)
        } catch {
            recoveryNotice = "The well could not be saved. Changes stay on this device until the next save."
        }
    }

    private func requestImmediateFlush() {
        writeTask?.cancel()
        flushTask = Task { [weak self] in
            await self?.flush()
        }
    }

    private func scheduleWrite() {
        writeTask?.cancel()
        writeTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.flush()
        }
    }

    private func persist(_ snapshot: AquiferFile) async throws {
        let data = try encoder.encode(snapshot)
        if (try await io.data(at: fileURL)) != nil {
            try await io.copy(fileURL, to: bakURL)
        }
        try await io.write(data, to: fileURL)
        try await io.copy(fileURL, to: backupURL)
    }

    private func decodeDocument(_ data: Data) -> AquiferFile? {
        do {
            let decoded = try decoder.decode(AquiferFile.self, from: data)
            return decoded
        } catch {
            return nil
        }
    }

    private func migrate(_ document: AquiferFile) -> AquiferFile {
        var next = document
        switch document.schemaVersion {
        case AquiferFile.currentSchemaVersion:
            break
        default:
            next.schemaVersion = AquiferFile.currentSchemaVersion
        }
        next.apply(next.intake)
        next.activityBonusMl = DrawBonus.snapped(next.activityBonusMl).rawValue
        next.sipVolumeMl = SipVolume.sanitized(next.sipVolumeMl)
        return next
    }

    private func ensureDay(_ dayKey: DayKey) {
        guard file.days[dayKey.rawValue] == nil else { return }
        file.days[dayKey.rawValue] = DayRecord.fresh(wakeVolumeMl: file.goal.millilitres)
    }

    private func canMutate(_ dayKey: DayKey, at date: Date) -> Bool {
        dayKey == DayKey.from(now(), calendar: calendar) && dayKey == DayKey.from(date, calendar: calendar)
    }

    private func applyCrossing(dayKey: DayKey, at date: Date) {
        guard var record = file.days[dayKey.rawValue] else { return }
        var inputs = inputs(dayKey: dayKey, at: date)
        inputs.day = record
        let projected = WellProjector.project(inputs)
        guard let mark = WellProjector.crossing(for: inputs, projected: projected) else { return }
        switch mark {
        case .ebb(let ebb):
            record.ebbMarks.append(ebb)
        case .stem(let stem):
            record.stemMarks.append(stem)
        }
        file.days[dayKey.rawValue] = record
    }

    private func inputs(dayKey: DayKey, at date: Date) -> WellProjector.Inputs {
        let record = file.days[dayKey.rawValue] ?? DayRecord.fresh(wakeVolumeMl: file.goal.millilitres)
        return WellProjector.Inputs(
            bodyKg: file.intake.bodyKg,
            wakeHour: file.intake.wakeHour,
            sleepHour: file.intake.sleepHour,
            dailyGoalMl: file.goal.millilitres,
            day: record,
            dayKey: dayKey,
            now: date,
            calendar: calendar
        )
    }
}

enum AquiferFlag {
    static let demo = "phr.demo.v1"
    static let intake = "phr.intake.done"
}
