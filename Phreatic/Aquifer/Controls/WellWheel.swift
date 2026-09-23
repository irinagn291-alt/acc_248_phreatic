import SwiftUI

/// Snapping value column. Outer rows stay ink-on-well above a contrast
/// floor — UIPickerView's fade is not used, so every drawn label reads.
struct WellWheel<Value: Hashable>: View {
    let values: [Value]
    @Binding var selection: Value
    var accessibilityName: String
    var label: (Value) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let rowHeight: CGFloat = SpaceToken.xl
    private let visibleRows = 5
    /// Neighbour ink blended on the well still clears 4.5:1.
    private let neighbourFloor: Double = 0.82

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(values, id: \.self) { value in
                        Button {
                            move(to: value, proxy: proxy)
                        } label: {
                            Text(label(value))
                                .font(TypeToken.body)
                                .foregroundStyle(ColorToken.ink)
                                .opacity(value == selection ? 1 : neighbourFloor)
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, minHeight: rowHeight)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(value)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .contentMargins(.vertical, rowHeight * CGFloat(padRows), for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: positionBinding)
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
            .onChange(of: selection) { _, newValue in
                scroll(to: newValue, proxy: proxy, animated: !reduceMotion)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: rowHeight * CGFloat(visibleRows))
        .background(
            ColorToken.surface,
            in: RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous)
        )
        .overlay {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle()
                    .fill(ColorToken.muted.opacity(0.35))
                    .frame(height: SpaceToken.hairline)
                Color.clear
                    .frame(height: rowHeight)
                Rectangle()
                    .fill(ColorToken.muted.opacity(0.35))
                    .frame(height: SpaceToken.hairline)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: RadiusToken.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(label(selection))
        .accessibilityAdjustableAction { direction in
            guard let index = values.firstIndex(of: selection) else { return }
            switch direction {
            case .increment:
                let next = values.index(after: index)
                if next < values.endIndex {
                    selection = values[next]
                }
            case .decrement:
                if index > values.startIndex {
                    selection = values[values.index(before: index)]
                }
            @unknown default:
                break
            }
        }
    }

    private var padRows: Int { (visibleRows - 1) / 2 }

    private var positionBinding: Binding<Value?> {
        Binding(
            get: { selection },
            set: { newValue in
                if let newValue, values.contains(newValue) {
                    selection = newValue
                }
            }
        )
    }

    private func move(to value: Value, proxy: ScrollViewProxy) {
        selection = value
        scroll(to: value, proxy: proxy, animated: !reduceMotion)
    }

    private func scroll(to value: Value, proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.18)) {
                proxy.scrollTo(value, anchor: .center)
            }
        } else {
            proxy.scrollTo(value, anchor: .center)
        }
    }
}
