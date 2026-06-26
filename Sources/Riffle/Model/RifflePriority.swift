import Foundation

/// The relative importance of a ``RiffleCard`` within a ``RiffleStack``.
///
/// Cards are ordered by priority, highest first. Within the same priority the
/// declaration order is preserved. Priority is backed by an `Int` raw value, so
/// you can define your own values between the built-in ones:
///
/// ```swift
/// extension RifflePriority {
///     static let critical = RifflePriority(rawValue: 1500)
/// }
/// ```
public struct RifflePriority: RawRepresentable, Comparable, Hashable, Sendable {
    /// The underlying priority value. Higher values sort earlier.
    public let rawValue: Int

    /// Creates a priority from a raw value.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Low priority. Shown after `.normal` and `.high` cards.
    public static let low = RifflePriority(rawValue: 0)

    /// The default priority.
    public static let normal = RifflePriority(rawValue: 500)

    /// High priority. Shown before `.normal` and `.low` cards.
    public static let high = RifflePriority(rawValue: 1000)

    /// Orders priorities by their raw value, lowest first.
    public static func < (lhs: RifflePriority, rhs: RifflePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
