import SwiftUI

/// History sheet. Cap grid of day seals, stave-hold streak as a sentence,
/// selected day expands to sips and marks on hairline rules.
struct HistorySheetView: View {
    @ObservedObject var store: AquiferStore
    var close: () -> Void

    @State private var selected: DayKey?
    @State private var retryBusy = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyPage
                } else {
                    populated
                }
            }
            .background(ColorToken.background.ignoresSafeArea())
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close", action: close)
                }
            }
        }
    }

    private var today: DayKey {
        DayKey.from(Date())
    }

    private var items: [DaySealItem] {
        DaySealGrid.items(from: store.file.days, excludingEmptyToday: today)
    }

    private var holdSummary: String {
        let window = Array(items.prefix(7))
        let todayItem = items.first(where: { $0.dayKey == today })
        return AquiferFormat.holdSummary(
            held: window.filter(\.held).count,
            total: window.count,
            todayHeld: todayItem?.held
        )
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpaceToken.md) {
                if let notice = store.recoveryNotice {
                    WellLoadErrorBanner(message: notice, retry: retry)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("Days behind you")
                        .font(TypeToken.title)
                        .foregroundStyle(ColorToken.ink)
                    Spacer(minLength: SpaceToken.xs)
                    Text(AquiferFormat.count(items.count))
                        .font(TypeToken.secondary)
                        .foregroundStyle(ColorToken.muted)
                        .monospacedDigit()
                }

                Text(holdSummary)
                    .font(TypeToken.caption)
                    .foregroundStyle(ColorToken.ink)
                    .fixedSize(horizontal: false, vertical: true)

                DaySealGrid(items: items, selected: selected) { item in
                    selected = selected == item.dayKey ? nil : item.dayKey
                }

                if let selected, let record = store.file.days[selected.rawValue] {
                    dayLedger(dayKey: selected, record: record)
                }
            }
            .padding(SpaceToken.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyPage: some View {
        VStack(spacing: SpaceToken.md) {
            if let notice = store.recoveryNotice {
                WellLoadErrorBanner(message: notice, retry: retry)
                    .padding(.horizontal, SpaceToken.md)
            }
            Spacer(minLength: SpaceToken.sm)
            Image("phr_EmptyHistoryLedger")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: SpaceToken.xl * 4)
                .clipped()
                .accessibilityHidden(true)
            Text("No days behind you yet")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
                .multilineTextAlignment(.center)
            Text("Today is the first one.")
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .multilineTextAlignment(.center)
            Button("Close", action: close)
                .buttonStyle(WellButtonStyle(kind: .primary))
                .padding(.horizontal, SpaceToken.md)
            Spacer(minLength: SpaceToken.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(SpaceToken.md)
    }

    @ViewBuilder
    private func dayLedger(dayKey: DayKey, record: DayRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AquiferFormat.dayTitle(dayKey))
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
                .padding(.bottom, SpaceToken.sm)

            let events = DayLedgerEvent.events(from: record)
            if events.isEmpty {
                Text("No sips or crossings on this day.")
                    .font(TypeToken.caption)
                    .foregroundStyle(ColorToken.muted)
            } else {
                ForEach(events) { event in
                    VStack(alignment: .leading, spacing: SpaceToken.xs) {
                        Rectangle()
                            .fill(ColorToken.muted.opacity(0.35))
                            .frame(height: SpaceToken.hairline)
                        HStack {
                            Text(event.title)
                                .font(TypeToken.body)
                                .foregroundStyle(ColorToken.ink)
                            Spacer(minLength: SpaceToken.xs)
                            Text(event.trailing)
                                .font(TypeToken.secondary)
                                .foregroundStyle(ColorToken.muted)
                                .monospacedDigit()
                        }
                        .padding(.vertical, SpaceToken.sm)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func retry() {
        guard !retryBusy else { return }
        retryBusy = true
        Task {
            await store.load()
            retryBusy = false
        }
    }
}

struct DayLedgerEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let recordedAt: Date
    let title: String
    let trailing: String

    static func events(from record: DayRecord) -> [DayLedgerEvent] {
        var rows: [DayLedgerEvent] = []
        rows.append(contentsOf: record.sips.map { sip in
            DayLedgerEvent(
                id: sip.id,
                recordedAt: sip.recordedAt,
                title: "Sip \(AquiferFormat.millilitresLabeled(sip.volumeMl))",
                trailing: AquiferFormat.timeOfDay(sip.recordedAt)
            )
        })
        rows.append(contentsOf: record.ebbMarks.map { mark in
            DayLedgerEvent(
                id: mark.id,
                recordedAt: mark.recordedAt,
                title: "Fell behind",
                trailing: AquiferFormat.timeOfDay(mark.recordedAt)
            )
        })
        rows.append(contentsOf: record.stemMarks.map { mark in
            DayLedgerEvent(
                id: mark.id,
                recordedAt: mark.recordedAt,
                title: "Caught up",
                trailing: AquiferFormat.timeOfDay(mark.recordedAt)
            )
        })
        return rows.sorted { $0.recordedAt < $1.recordedAt }
    }
}
