import SwiftUI

/// Top plate: app name and remaining millilitres. ViewThatFits drops the
/// time-to-stave line, then the remaining line, so AX5 never clips.
struct WellChrome: View {
    let level: WellLevel

    @ScaledMetric(relativeTo: .largeTitle) private var readoutWidth: CGFloat = 200
    @ScaledMetric(relativeTo: .largeTitle) private var readoutSize: CGFloat = 56

    var body: some View {
        VStack(alignment: .leading, spacing: SpaceToken.xs) {
            Image("phr_HeaderDecor")
                .interpolation(.none)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: SpaceToken.lg, maxHeight: SpaceToken.xl)
                .clipped()
                .accessibilityHidden(true)

            Text("Phreatic")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)

            Text(AquiferFormat.homeJobLine(remainingMl: level.remainingMl))
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.ink)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                fullReadout
                remainingOnly
                bareReadout
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fullReadout: some View {
        HStack(alignment: .firstTextBaseline, spacing: SpaceToken.xs) {
            bareReadout
            Text("ml remaining")
                .font(TypeToken.unit)
                .foregroundStyle(ColorToken.muted)
            if let seconds = level.secondsToStave {
                Text(AquiferFormat.minutesUntilStave(seconds))
                    .font(TypeToken.secondary)
                    .foregroundStyle(ColorToken.muted)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
    }

    private var remainingOnly: some View {
        HStack(alignment: .firstTextBaseline, spacing: SpaceToken.xs) {
            bareReadout
            Text("ml remaining")
                .font(TypeToken.unit)
                .foregroundStyle(ColorToken.muted)
        }
    }

    private var bareReadout: some View {
        Text(AquiferFormat.millilitres(level.remainingMl))
            .font(TypeToken.display(size: readoutSize))
            .foregroundStyle(ColorToken.ink)
            .monospacedDigit()
            .frame(minWidth: readoutWidth * 0.55, alignment: .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

/// Full-page empty day inside the well column.
struct WellEmptyState: View {
    var logSip: () -> Void

    var body: some View {
        VStack(spacing: SpaceToken.md) {
            Image("phr_EmptyDayStone")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: SpaceToken.xl * 4)
                .clipped()
                .accessibilityHidden(true)
            Text("The day just started")
                .font(TypeToken.title)
                .foregroundStyle(ColorToken.ink)
                .multilineTextAlignment(.center)
            Text("First glass, best start.")
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.muted)
                .multilineTextAlignment(.center)
            Button("Log a sip", action: logSip)
                .buttonStyle(WellButtonStyle(kind: .primary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(SpaceToken.md)
    }
}

struct WellLoadErrorBanner: View {
    let message: String
    var retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpaceToken.xs) {
            Text(message)
                .font(TypeToken.caption)
                .foregroundStyle(ColorToken.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again", action: retry)
                .buttonStyle(WellButtonStyle(kind: .secondary))
        }
        .padding(SpaceToken.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
    }
}
