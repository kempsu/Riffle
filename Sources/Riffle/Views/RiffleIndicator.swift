import SwiftUI

/// The page indicator style for a ``RiffleStack``.
///
/// The indicator reflects the eligible-card count and the current index, and is
/// hidden automatically when there are fewer than two cards.
///
/// ```swift
/// RiffleStack { /* cards */ }
///     .riffleIndicator(.bars)
/// ```
public struct RiffleIndicator {
    enum Style {
        case none
        case dots
        case bars
        case custom((_ count: Int, _ index: Int) -> AnyView)
    }

    let style: Style

    /// No indicator.
    public static var none: RiffleIndicator { RiffleIndicator(style: .none) }

    /// A row of dots, one per card, with the current card filled.
    public static var dots: RiffleIndicator { RiffleIndicator(style: .dots) }

    /// A row of bars with the current card highlighted and widened.
    public static var bars: RiffleIndicator { RiffleIndicator(style: .bars) }

    /// A caller-supplied indicator.
    ///
    /// - Parameter content: A view builder receiving the card count and the
    ///   current index.
    public static func custom<V: View>(
        @ViewBuilder _ content: @escaping (_ count: Int, _ index: Int) -> V
    ) -> RiffleIndicator {
        RiffleIndicator(style: .custom { count, index in AnyView(content(count, index)) })
    }
}

/// Renders a ``RiffleIndicator`` for a given count and index.
@MainActor
struct RiffleIndicatorView: View {
    let indicator: RiffleIndicator
    let count: Int
    let index: Int
    var tint: Color? = nil
    var onSelect: (Int) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .footnote) private var dotSize: CGFloat = 6
    @ScaledMetric(relativeTo: .footnote) private var barHeight: CGFloat = 4
    @ScaledMetric(relativeTo: .footnote) private var barWidth: CGFloat = 6
    @ScaledMetric(relativeTo: .footnote) private var activeBarWidth: CGFloat = 16

    /// The active color: the supplied tint, or the adaptive default.
    private var activeColor: Color { tint ?? .primary }
    /// The inactive color: a faded tint, or the adaptive default.
    private func inactiveColor(_ opacity: Double) -> Color {
        (tint ?? .secondary).opacity(opacity)
    }

    var body: some View {
        switch indicator.style {
        case .none:
            EmptyView()
        case .dots:
            row { idx in
                Circle()
                    .fill(idx == index ? activeColor : inactiveColor(0.4))
                    .frame(width: dotSize, height: dotSize)
            }
        case .bars:
            row { idx in
                Capsule()
                    .fill(idx == index ? activeColor : inactiveColor(0.35))
                    .frame(width: idx == index ? activeBarWidth : barWidth, height: barHeight)
            }
        case .custom(let make):
            make(count, index)
        }
    }

    private func row<Item: View>(@ViewBuilder _ item: @escaping (Int) -> Item) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { idx in
                item(idx)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(idx) }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: index)
    }
}
