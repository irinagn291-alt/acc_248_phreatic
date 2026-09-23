import Foundation

/// Simulator-only shelf. Lands mid-morning with one prior sip already
/// draining so the opening tap can stem. Never runs on a device.
enum DemoSeed {
    static func installIfNeeded(directory: URL, defaults: UserDefaults) async {
        #if targetEnvironment(simulator)
        guard defaults.bool(forKey: AquiferFlag.demo) == false else { return }
        let io = AquiferFileIO()
        let url = directory.appendingPathComponent("well.plist")
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            let data = try encoder.encode(makeFile(now: Date(), calendar: .current))
            try await io.write(data, to: url)
            defaults.set(true, forKey: AquiferFlag.demo)
            defaults.set(true, forKey: AquiferFlag.intake)
        } catch {
            defaults.set(true, forKey: AquiferFlag.demo)
            defaults.set(true, forKey: AquiferFlag.intake)
        }
        #endif
    }

    static func makeFile(now: Date, calendar: Calendar) -> AquiferFile {
        let intake = WakeIntake(bodyKg: 70, wakeHour: 7, sleepHour: 23)
        let goal = RechargeGoal(weightKg: intake.bodyKg, activityBonusMl: DrawBonus.still.rawValue)
        var file = AquiferFile.empty
        file.apply(intake)
        file.activityBonusMl = DrawBonus.still.rawValue
        file.sipVolumeMl = SipVolume.defaultMl

        let today = DayKey.from(now, calendar: calendar)
        var todayRecord = DayRecord.fresh(wakeVolumeMl: goal.millilitres)
        let sipAt = now.addingTimeInterval(-2 * 60 * 60)
        todayRecord.sips = [
            Sip(recordedAt: sipAt, dayKey: today.rawValue, volumeMl: SipVolume.defaultMl)
        ]
        let stave = Stave.thresholdMl(dailyGoalMl: goal.millilitres)
        todayRecord.ebbMarks = [
            EbbMark(
                recordedAt: sipAt.addingTimeInterval(-40 * 60),
                dayKey: today.rawValue,
                levelMl: Double(stave - 30)
            )
        ]
        todayRecord.stemMarks = [
            StemMark(
                recordedAt: sipAt,
                dayKey: today.rawValue,
                levelMl: Double(stave + 80)
            )
        ]
        file.days[today.rawValue] = todayRecord

        let prior: [(offset: Int, sips: Int, ebb: Bool)] = [
            (1, 4, false),
            (2, 2, true),
            (3, 5, false),
            (4, 1, true),
            (5, 3, false),
            (6, 2, true),
        ]
        for row in prior {
            guard let date = calendar.date(byAdding: .day, value: -row.offset, to: now) else { continue }
            let key = DayKey.from(date, calendar: calendar)
            var record = DayRecord.fresh(wakeVolumeMl: goal.millilitres)
            let start = key.startOfDay(calendar: calendar)
            let wake = DrawDown.hourDate(dayStart: start, hour: intake.wakeHour, calendar: calendar)
            record.sips = (0..<row.sips).map { index in
                Sip(
                    recordedAt: wake.addingTimeInterval(TimeInterval((index + 1) * 90 * 60)),
                    dayKey: key.rawValue,
                    volumeMl: SipVolume.defaultMl
                )
            }
            if row.ebb {
                record.ebbMarks = [
                    EbbMark(
                        recordedAt: wake.addingTimeInterval(8 * 60 * 60),
                        dayKey: key.rawValue,
                        levelMl: Stave.thresholdMl(dailyGoalMl: goal.millilitres) - 20
                    )
                ]
            }
            file.days[key.rawValue] = record
        }
        return file
    }
}
