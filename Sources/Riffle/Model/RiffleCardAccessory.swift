import SwiftUI

/// The trailing accessory of a ``RiffleStandardCard`` — the small glyph at the right
/// edge that hints the card is tappable.
///
/// ```swift
/// .chevron              // the default trailing chevron
/// .none                 // no accessory
/// .symbol("arrow.up.right")   // any SF Symbol
/// ```
public struct RiffleCardAccessory: Sendable, Equatable {
    /// The SF Symbol to show, or `nil` for no accessory.
    let symbol: String?

    private init(symbol: String?) {
        self.symbol = symbol
    }

    /// No trailing accessory.
    public static let none = RiffleCardAccessory(symbol: nil)

    /// A trailing chevron — the default for a tappable card.
    public static let chevron = RiffleCardAccessory(symbol: "chevron.right")

    /// A custom SF Symbol as the trailing accessory.
    public static func symbol(_ systemName: String) -> RiffleCardAccessory {
        RiffleCardAccessory(symbol: systemName)
    }
}
