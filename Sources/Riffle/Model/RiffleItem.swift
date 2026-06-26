import Foundation

/// A model value that can drive a data-driven ``RiffleStack``.
///
/// Conform your promo, announcement, or tip model to `RiffleItem` to supply
/// ordering and eligibility without the declarative builder. The data-driven
/// initializer that consumes this protocol arrives in a later release; the
/// protocol is defined now so the contract is stable.
public protocol RiffleItem: Identifiable {
    /// The relative importance of this item. Defaults to `.normal`.
    var priority: RifflePriority { get }

    /// Whether this item is currently eligible to be shown. Defaults to `true`.
    var isEligible: Bool { get }
}

public extension RiffleItem {
    var priority: RifflePriority { .normal }
    var isEligible: Bool { true }
}
