import SwiftUI

/// Two-up cap grid. Count is visible. Never three equal cards.
struct DaySealItem: Identifiable, Equatable, Sendable {
    var id: Int { dayKey.rawValue }
    let dayKey: DayKey
    let record: DayRecord

    var held: Bool { StaveHold.isHold(record) }
}

struct DaySealGrid: View {
    let items: [DaySealItem]
    let selected: DayKey?
    var onSelect: (DaySealItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: SpaceToken.sm),
        GridItem(.flexible(), spacing: SpaceToken.sm),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: SpaceToken.sm) {
            ForEach(items) { item in
                SealTile(
                    title: AquiferFormat.dayCardTitle(item.dayKey),
                    caption: item.held ? "Held" : "Fell behind",
                    held: item.held,
                    selected: selected == item.dayKey,
                    action: { onSelect(item) }
                )
            }
        }
    }

    static func items(from days: [Int: DayRecord], excludingEmptyToday today: DayKey? = nil) -> [DaySealItem] {
        days.keys.sorted(by: >).compactMap { raw in
            guard let record = days[raw] else { return nil }
            let key = DayKey(rawValue: raw)
            if let today, key == today, record.sips.isEmpty, record.ebbMarks.isEmpty, record.stemMarks.isEmpty {
                return nil
            }
            return DaySealItem(dayKey: key, record: record)
        }
    }

    static func weekItems(
        from days: [Int: DayRecord],
        through today: DayKey,
        calendar: Calendar = .current
    ) -> [DaySealItem] {
        (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today.startOfDay(calendar: calendar)) else {
                return nil
            }
            let key = DayKey.from(date, calendar: calendar)
            guard let record = days[key.rawValue] else { return nil }
            if key == today, record.sips.isEmpty, record.ebbMarks.isEmpty, record.stemMarks.isEmpty {
                return nil
            }
            return DaySealItem(dayKey: key, record: record)
        }
    }
}

struct TodaySipTimeline: View {
    let sips: [Sip]
    var openHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpaceToken.xs) {
            HStack {
                Text("Today's sips")
                    .font(TypeToken.title)
                    .foregroundStyle(ColorToken.ink)
                Spacer(minLength: SpaceToken.xs)
                Text(AquiferFormat.count(sips.count))
                    .font(TypeToken.secondary)
                    .foregroundStyle(ColorToken.muted)
                    .monospacedDigit()
            }
            if sips.isEmpty {
                Text("No sips yet. Log the first glass to start the day.")
                    .font(TypeToken.caption)
                    .foregroundStyle(ColorToken.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(sips.sorted { $0.recordedAt > $1.recordedAt }) { sip in
                    Button(action: openHistory) {
                        HStack {
                            Text("Sip \(AquiferFormat.millilitresLabeled(sip.volumeMl))")
                                .font(TypeToken.body)
                                .foregroundStyle(ColorToken.ink)
                            Spacer(minLength: SpaceToken.xs)
                            Text(AquiferFormat.timeOfDay(sip.recordedAt))
                                .font(TypeToken.secondary)
                                .foregroundStyle(ColorToken.muted)
                                .monospacedDigit()
                        }
                        .padding(SpaceToken.sm)
                        .frame(maxWidth: .infinity, minHeight: SpaceToken.unit * 6, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Sip \(AquiferFormat.millilitresLabeled(sip.volumeMl)) at \(AquiferFormat.timeOfDay(sip.recordedAt))")
                    .accessibilityHint("Opens history.")
                }
            }
        }
    }
}

struct DrainRateCard: View {
    let level: WellLevel
    let doubled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SpaceToken.xs) {
            Text("Drain now")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            Text(AquiferFormat.millilitresPerMinute(level.currentRateMlPerMinute))
                .font(TypeToken.body)
                .foregroundStyle(ColorToken.ink)
                .monospacedDigit()
            Text(
                doubled
                    ? "Activity is doubling the drain for one hour."
                    : "Activity doubles the drain for one hour."
            )
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(SpaceToken.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
    }
}

struct WeekHoldStrip: View {
    let items: [DaySealItem]
    var openDay: (DaySealItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpaceToken.xs) {
            Text("Last 7 days")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SpaceToken.xs) {
                    ForEach(items) { item in
                        Button {
                            openDay(item)
                        } label: {
                            VStack(alignment: .leading, spacing: SpaceToken.unit / 2) {
                                Text(AquiferFormat.dayCardTitle(item.dayKey))
                                    .font(TypeToken.body.weight(.semibold))
                                    .foregroundStyle(ColorToken.ink)
                                    .lineLimit(1)
                                Text(item.held ? "Held" : "Fell behind")
                                    .font(TypeToken.caption)
                                    .foregroundStyle(ColorToken.muted)
                                    .lineLimit(1)
                            }
                            .padding(SpaceToken.sm)
                            .frame(minWidth: SpaceToken.xl * 2.4, minHeight: SpaceToken.unit * 6, alignment: .leading)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(AquiferFormat.dayCardTitle(item.dayKey)), \(item.held ? "Held" : "Fell behind")")
                        .accessibilityHint("Opens history.")
                    }
                }
            }
        }
    }
}
