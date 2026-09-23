import SwiftUI

/// First-launch intake. Four pages: what the well is, the home verb, body
/// weight, waking hours. Skip writes fallback defaults. Continue is pinned
/// full width at the bottom.
struct IntakeFlowView: View {
    var onFinish: (WakeIntake) -> Void

    @State private var page = 0
    @State private var bodyKg: Int = Int(WakeIntake.fallback.bodyKg.rounded())
    @State private var wakeHour: Int = WakeIntake.fallback.wakeHour
    @State private var sleepHour: Int = WakeIntake.fallback.sleepHour

    private let lastPage = 3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var readoutSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch page {
                case 0:
                    explainPage(
                        image: "phr_Onboarding1",
                        headline: "The well starts full",
                        line: "At wake the water table is at the daily goal. It falls through the hours you are up."
                    )
                case 1:
                    explainPage(
                        image: "phr_Onboarding2",
                        headline: "Stem the ebb",
                        line: "Log a sip to push the table back up. Stay above the stave and the day is held."
                    )
                case 2:
                    weightPage
                default:
                    hoursPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(page)
            .transition(.opacity)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: page)

            VStack(spacing: SpaceToken.sm) {
                Button("Skip") {
                    onFinish(WakeIntake.fallback)
                }
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .frame(minHeight: SpaceToken.xl)
                .contentShape(Rectangle())

                Button(page == lastPage ? "Continue" : "Continue") {
                    if page < lastPage {
                        page += 1
                    } else {
                        onFinish(
                            WakeIntake(bodyKg: Double(bodyKg), wakeHour: wakeHour, sleepHour: sleepHour)
                        )
                    }
                }
                .buttonStyle(WellButtonStyle(kind: .primary))
            }
            .padding(.horizontal, SpaceToken.md)
            .padding(.bottom, SpaceToken.sm)
        }
        .background(ColorToken.background.ignoresSafeArea())
        .tint(ColorToken.accent)
    }

    private func explainPage(image: String, headline: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: SpaceToken.md) {
            Image(image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: SpaceToken.xl * 7)
                .clipped()
                .accessibilityHidden(true)
            Text(headline)
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            Text(line)
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: SpaceToken.sm)
        }
        .padding(SpaceToken.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var weightPage: some View {
        VStack(alignment: .leading, spacing: SpaceToken.md) {
            Image("phr_Onboarding3")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: SpaceToken.xl * 4)
                .clipped()
                .accessibilityHidden(true)
            Text("Body weight")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            Text("The daily well is sized from your weight. This is a personal target, not medical advice.")
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text(AquiferFormat.kilograms(Double(bodyKg)))
                .font(TypeToken.display(size: readoutSize))
                .foregroundStyle(ColorToken.ink)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)
            WellWheel(
                values: Array(stride(from: 20, through: 300, by: 1)),
                selection: $bodyKg,
                accessibilityName: "Body weight in kilograms",
                label: { AquiferFormat.kilograms(Double($0)) }
            )
        }
        .padding(SpaceToken.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var hoursPage: some View {
        VStack(alignment: .leading, spacing: SpaceToken.md) {
            Image("phr_EmptyHome")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: SpaceToken.xl * 3)
                .clipped()
                .accessibilityHidden(true)
            Text("Waking hours")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
            Text("Wake and sleep mark when the table begins to fall and when it should reach empty.")
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: SpaceToken.sm) {
                hourColumn(title: "Wake", selection: $wakeHour)
                hourColumn(title: "Sleep", selection: $sleepHour)
            }
            .frame(maxWidth: .infinity, minHeight: SpaceToken.xl * 4)
        }
        .padding(SpaceToken.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func hourColumn(title: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: SpaceToken.xs) {
            Text(title)
                .font(TypeToken.body)
                .foregroundStyle(ColorToken.ink)
            Text(AquiferFormat.clockHour(selection.wrappedValue))
                .font(TypeToken.secondary)
                .foregroundStyle(ColorToken.muted)
                .monospacedDigit()
            WellWheel(
                values: Array(0..<24),
                selection: selection,
                accessibilityName: title,
                label: AquiferFormat.clockHour
            )
        }
        .frame(maxWidth: .infinity)
    }
}
