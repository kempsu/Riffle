import SwiftUI

/// The resolved set of options that drive a ``RiffleStack``.
///
/// This type is internal on purpose. Configure a stack through the `riffle*`
/// view modifiers, which write into the value carried in the SwiftUI environment
/// so settings compose at any level of the view tree.
struct RiffleConfiguration {
    var transition: RiffleTransition = .flip
    var autoAdvance: RiffleAdvance = .off
    var pausesOnInteraction: Bool = true
    var loops: Bool = true
    var indicator: RiffleIndicator = .dots
    /// Overrides the indicator's color. `nil` uses the adaptive default.
    var indicatorTint: Color? = nil
    var stackDepth: Int = 2
    /// Whether the front card casts a soft drop shadow.
    var cardShadow: Bool = true
    /// Whether a single-card stack still responds to manual swipe gestures. A stack
    /// with one card has nowhere to navigate, so by default a swipe is ignored
    /// rather than flipping the card to itself.
    var allowsSingleCardGestures: Bool = false
}
