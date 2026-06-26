import Foundation

/// Controls automatic rotation between cards in a ``RiffleStack``.
public enum RiffleAdvance: Equatable, Sendable {
    /// Auto-advance is disabled. Cards change only on user interaction.
    case off

    /// Advance to the next card every given number of seconds.
    case seconds(TimeInterval)

    /// The advance interval in seconds, or `nil` when auto-advance is off or the
    /// interval is not positive.
    var interval: TimeInterval? {
        switch self {
        case .off:
            return nil
        case .seconds(let value):
            // Require a finite, positive interval; a non-runnable value simply
            // means "no auto-advance" rather than feeding a trap into Task.sleep.
            return value.isFinite && value > 0 ? value : nil
        }
    }
}
