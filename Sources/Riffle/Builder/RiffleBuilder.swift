import SwiftUI

/// An eligibility- and priority-tagged card whose content has been type-erased.
///
/// Erasure is required because the builder collects heterogeneous card views and
/// the engine filters and reorders them at runtime. This type is internal, so the
/// `AnyView` never appears in the public API.
struct ResolvedCard {
    let id: AnyHashable
    let priority: RifflePriority
    let isEligible: Bool
    let content: AnyView
    /// Primary tap action; when set, the front card becomes tappable.
    let action: (() -> Void)?
    /// Dismiss action; when set, exposes a "Dismiss" affordance/accessibility action.
    let onDismiss: (() -> Void)?

    init(
        id: AnyHashable,
        priority: RifflePriority,
        isEligible: Bool,
        content: AnyView,
        action: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.id = id
        self.priority = priority
        self.isEligible = isEligible
        self.content = content
        self.action = action
        self.onDismiss = onDismiss
    }
}

/// The opaque result of a ``RiffleStack`` card list, produced by ``RiffleBuilder``.
///
/// You never construct or inspect this directly; it exists only to carry the
/// collected cards from the builder into the stack while keeping the erased card
/// content out of the public API.
public struct RiffleContent {
    let cards: [ResolvedCard]

    init(_ cards: [ResolvedCard]) {
        self.cards = cards
    }
}

/// Collects the ``RiffleCard`` values declared inside a ``RiffleStack``.
@MainActor
@resultBuilder
public enum RiffleBuilder {
    /// Wraps a single card in the builder's result type.
    public static func buildExpression<C: View>(_ card: RiffleCard<C>) -> RiffleContent {
        RiffleContent([card.resolve()])
    }

    /// Concatenates the cards declared in a block, preserving order.
    public static func buildBlock(_ components: RiffleContent...) -> RiffleContent {
        RiffleContent(components.flatMap(\.cards))
    }

    /// Supports `if` without `else`: a skipped branch contributes no cards.
    public static func buildOptional(_ component: RiffleContent?) -> RiffleContent {
        component ?? RiffleContent([])
    }

    /// Supports the first branch of an `if`/`else` or `switch`.
    public static func buildEither(first component: RiffleContent) -> RiffleContent {
        component
    }

    /// Supports the second branch of an `if`/`else` or `switch`.
    public static func buildEither(second component: RiffleContent) -> RiffleContent {
        component
    }

    /// Supports `for` loops by flattening their per-iteration cards.
    public static func buildArray(_ components: [RiffleContent]) -> RiffleContent {
        RiffleContent(components.flatMap(\.cards))
    }

    /// Supports `if #available(...)` availability blocks.
    public static func buildLimitedAvailability(_ component: RiffleContent) -> RiffleContent {
        component
    }
}
