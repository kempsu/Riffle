import SwiftUI

/// A single card in a ``RiffleStack``.
///
/// Give every card a stable `id` and supply its content with a view builder.
/// Set its importance and eligibility with ``priority(_:)`` and ``shown(when:)``:
///
/// ```swift
/// RiffleCard(id: "pro") {
///     ProUpsellView()
/// }
/// .priority(.high)
/// .shown(when: !entitlements.isPro)
/// ```
///
/// A card is a value collected by ``RiffleBuilder``; you don't render it directly.
@MainActor
public struct RiffleCard<Content: View> {
    private let id: AnyHashable
    private let content: Content
    private var metadata: Metadata

    private struct Metadata {
        var priority: RifflePriority = .normal
        var isEligible: Bool = true
        var action: (() -> Void)?
        var onDismiss: (() -> Void)?
    }

    /// Creates a card with a stable identity and view content.
    ///
    /// - Parameters:
    ///   - id: A stable, unique identifier used to track the card across updates.
    ///   - content: A view builder producing the card's content.
    public init(id: some Hashable, @ViewBuilder content: () -> Content) {
        self.id = AnyHashable(id)
        self.content = content()
        self.metadata = Metadata()
    }

    /// Sets the card's priority. Higher-priority cards are shown first.
    public func priority(_ priority: RifflePriority) -> RiffleCard {
        var copy = self
        copy.metadata.priority = priority
        return copy
    }

    /// Includes the card only when `condition` is `true`.
    public func shown(when condition: Bool) -> RiffleCard {
        var copy = self
        copy.metadata.isEligible = condition
        return copy
    }

    /// Runs `action` when the card is tapped, making the whole card tappable.
    ///
    /// ```swift
    /// RiffleCard(id: "pro") { ProUpsellView() }
    ///     .onTap { showPaywall() }
    /// ```
    public func onTap(_ action: @escaping () -> Void) -> RiffleCard {
        var copy = self
        copy.metadata.action = action
        return copy
    }

    func resolve() -> ResolvedCard {
        ResolvedCard(
            id: id,
            priority: metadata.priority,
            isEligible: metadata.isEligible,
            content: AnyView(content),
            action: metadata.action,
            onDismiss: metadata.onDismiss
        )
    }
}

extension RiffleCard where Content == RiffleStandardCard {
    /// Creates a card using the built-in ``RiffleStandardCard`` layout, so a tappable,
    /// optionally dismissible promo needs no custom view.
    ///
    /// ```swift
    /// RiffleStack {
    ///     RiffleCard(id: "rate",
    ///                title: "Enjoying the app?",
    ///                message: "Leave a quick review.",
    ///                systemImage: "star.fill",
    ///                background: .gradient(light: [.yellow, .orange], dark: [.orange, .brown]),
    ///                action: { requestReview() },
    ///                onDismiss: { hasRated = true })
    ///         .shown(when: !hasRated)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - id: A stable, unique identifier used to track the card across updates.
    ///   - title: The card's headline.
    ///   - message: An optional supporting line beneath the title.
    ///   - systemImage: An optional leading SF Symbol name.
    ///   - background: The card's background. Defaults to a solid accent color. Use a
    ///     ``RiffleCardBackground`` for gradients, images, or distinct light/dark variants.
    ///   - accent: An optional decorative image (a "sticker"). Use ``RiffleCardAccent``
    ///     to control its size, corner, offset, rotation, and opacity.
    ///   - accessory: The trailing glyph (``RiffleCardAccessory``). Pass `.none` to hide
    ///     it or `.symbol(_:)` for a custom one. Defaults to a chevron when the card has
    ///     an `action`, otherwise none.
    ///   - action: Runs when the card is tapped.
    ///   - onDismiss: When set, the card becomes dismissable: a circled close button is
    ///     shown that calls this closure (typically to flip the state behind `shown(when:)`).
    public init(
        id: some Hashable,
        title: String,
        message: String? = nil,
        systemImage: String? = nil,
        background: RiffleCardBackground = .color(.accentColor),
        accent: RiffleCardAccent? = nil,
        accessory: RiffleCardAccessory? = nil,
        action: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.init(id: id) {
            RiffleStandardCard(
                title: title,
                message: message,
                systemImage: systemImage,
                background: background,
                accent: accent,
                accessory: accessory ?? (action != nil ? .chevron : .none),
                onDismiss: onDismiss
            )
        }
        metadata.action = action
        metadata.onDismiss = onDismiss
    }
}
