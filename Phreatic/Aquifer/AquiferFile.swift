import Foundation

/// On-disk document. WellLevel is never a field: the file only grows with
/// append-only events, and any past day recomputes from these bytes.
struct AquiferFile: Sendable, Equatable {
    var schemaVersion: Int
    var bodyKg: Double
    var wakeHour: Int
    var sleepHour: Int
    var activityBonusMl: Int
    var sipVolumeMl: Int
    var days: [Int: DayRecord]

    static let currentSchemaVersion = 1

    static var empty: AquiferFile {
        let intake = WakeIntake.fallback
        return AquiferFile(
            schemaVersion: currentSchemaVersion,
            bodyKg: intake.bodyKg,
            wakeHour: intake.wakeHour,
            sleepHour: intake.sleepHour,
            activityBonusMl: DrawBonus.still.rawValue,
            sipVolumeMl: SipVolume.defaultMl,
            days: [:]
        )
    }

    var intake: WakeIntake {
        WakeIntake(bodyKg: bodyKg, wakeHour: wakeHour, sleepHour: sleepHour).sanitized
    }

    var goal: RechargeGoal {
        RechargeGoal(weightKg: intake.bodyKg, activityBonusMl: activityBonusMl)
    }

    mutating func apply(_ intake: WakeIntake) {
        let clean = intake.sanitized
        bodyKg = clean.bodyKg
        wakeHour = clean.wakeHour
        sleepHour = clean.sleepHour
    }
}

/// One calendar day's events. Holds no level field.
struct DayRecord: Sendable, Equatable, Codable {
    var wakeVolumeMl: Int
    var sips: [Sip]
    var activities: [Activity]
    var ebbMarks: [EbbMark]
    var stemMarks: [StemMark]

    static func fresh(wakeVolumeMl: Int) -> DayRecord {
        DayRecord(
            wakeVolumeMl: wakeVolumeMl,
            sips: [],
            activities: [],
            ebbMarks: [],
            stemMarks: []
        )
    }

    var ledger: RechargeLedger {
        get {
            let key = sips.first.map { DayKey(rawValue: $0.dayKey) }
                ?? activities.first.map { DayKey(rawValue: $0.dayKey) }
                ?? DayKey(rawValue: 0)
            return RechargeLedger(dayKey: key, sips: sips, activities: activities)
        }
        set {
            sips = newValue.sips
            activities = newValue.activities
        }
    }
}

extension AquiferFile: Codable {
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case version
        case bodyKg
        case wakeHour
        case sleepHour
        case activityBonusMl
        case sipVolumeMl
        case days
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let schema = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) {
            schemaVersion = schema
        } else {
            schemaVersion = try container.decodeIfPresent(Int.self, forKey: .version) ?? Self.currentSchemaVersion
        }
        bodyKg = try container.decodeIfPresent(Double.self, forKey: .bodyKg) ?? WakeIntake.fallback.bodyKg
        wakeHour = try container.decodeIfPresent(Int.self, forKey: .wakeHour) ?? WakeIntake.fallback.wakeHour
        sleepHour = try container.decodeIfPresent(Int.self, forKey: .sleepHour) ?? WakeIntake.fallback.sleepHour
        activityBonusMl = try container.decodeIfPresent(Int.self, forKey: .activityBonusMl) ?? DrawBonus.still.rawValue
        sipVolumeMl = try container.decodeIfPresent(Int.self, forKey: .sipVolumeMl) ?? SipVolume.defaultMl
        let rawDays = try container.decodeIfPresent([String: DayRecord].self, forKey: .days) ?? [:]
        days = Dictionary(uniqueKeysWithValues: rawDays.compactMap { key, value in
            Int(key).map { ($0, value) }
        })
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(schemaVersion, forKey: .version)
        try container.encode(bodyKg, forKey: .bodyKg)
        try container.encode(wakeHour, forKey: .wakeHour)
        try container.encode(sleepHour, forKey: .sleepHour)
        try container.encode(activityBonusMl, forKey: .activityBonusMl)
        try container.encode(sipVolumeMl, forKey: .sipVolumeMl)
        let rawDays = Dictionary(uniqueKeysWithValues: days.map { (String($0.key), $0.value) })
        try container.encode(rawDays, forKey: .days)
    }
}
