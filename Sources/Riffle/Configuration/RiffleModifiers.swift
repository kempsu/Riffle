import SwiftUI

public extension View {
    /// Sets the transition used when the front card changes. Defaults to `.flip`.
    func riffleTransition(_ transition: RiffleTransition) -> some View {
        transformEnvironment(\.riffleConfiguration) { $0.transition = transition }
    }

    /// Configures automatic rotation between cards. Defaults to `.off`.
    func riffleAutoAdvance(_ advance: RiffleAdvance) -> some View {
        transformEnvironment(\.riffleConfiguration) { $0.autoAdvance = advance }
    }

    /// When `true`, interaction pauses auto-advance during the gesture and for one
    /// full interval afterward. Defaults to `true`.
    func rifflePausesOnInteraction(_ pauses: Bool) -> some View {
        transformEnvironment(\.riffleConfiguration) { $0.pausesOnInteraction = pauses }
    }

    /// When `true`, navigation wraps around the ends. When `false`, it stops at
    /// the first and last cards. Defaults to `true`.
    func riffleLoops(_ loops: Bool) -> some View {
        transformEnvironment(\.riffleConfiguration) { $0.loops = loops }
    }

    /// Sets the page indicator style. Defaults to `.dots`. Use `.none` to hide it.
    func riffleIndicator(_ indicator: RiffleIndicator) -> some View {
        transformEnvironment(\.riffleConfiguration) { $0.indicator = indicator }
    }

    /// Tints the page indicator. Pass `nil` (the default) to use the adaptive,
    /// color-scheme-aware default color.
    func riffleIndicatorTint(_ color: Color?) -> some View {
        transformEnvironment(\.riffleConfiguration) { $0.indicatorTint = color }
    }

    /// The number of cards that peek behind the front card, like a deck. `0`
    /// shows only the front card. Defaults to `2`.
    func riffleStackDepth(_ depth: Int) -> some View {
        transformEnvironment(\.riffleConfiguration) { $0.stackDepth = max(0, depth) }
    }

    /// Whether the front card casts a soft drop shadow. Defaults to `true`.
    func riffleCardShadow(_ enabled: Bool) -> some View {
        transformEnvironment(\.riffleConfiguration) { $0.cardShadow = enabled }
    }
}
