import SwiftUI

/// The direction the stack is moving, used to make insertion and removal
/// transitions asymmetric so a flip or slide reads as a single motion.
enum RiffleDirection {
    /// Advancing to the next card (swipe up).
    case forward
    /// Returning to the previous card (swipe down).
    case backward
}

extension RiffleTransition {
    /// Resolves to a concrete `AnyTransition`, degrading to a cross-fade when
    /// Reduce Motion is enabled.
    func resolvedTransition(direction: RiffleDirection, reduceMotion: Bool) -> AnyTransition {
        if reduceMotion { return .opacity }
        switch self {
        case .flip:
            return .riffleFlip(direction: direction)
        case .slide:
            return .riffleSlide(direction: direction)
        case .push:
            return .rifflePush(direction: direction)
        case .fade:
            return .opacity
        case .scale:
            return .scale(scale: 0.85).combined(with: .opacity)
        case .custom(let transition):
            return transition
        }
    }
}

private struct RiffleFlipModifier: ViewModifier {
    let angle: Double

    func body(content: Content) -> some View {
        content
            .opacity(max(0, 1 - abs(angle) / 90))
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.5
            )
    }
}

extension AnyTransition {
    /// A vertical 3D flip around the card's horizontal centre, cross-fading through
    /// the edge-on midpoint so it reads as a single motion.
    static func riffleFlip(direction: RiffleDirection) -> AnyTransition {
        let sign: Double = direction == .forward ? 1 : -1
        return .asymmetric(
            insertion: .modifier(active: RiffleFlipModifier(angle: -90 * sign),
                                 identity: RiffleFlipModifier(angle: 0)),
            removal: .modifier(active: RiffleFlipModifier(angle: 90 * sign),
                               identity: RiffleFlipModifier(angle: 0))
        )
    }

    /// A vertical slide whose direction follows navigation. Pure movement — the
    /// outgoing card travels fully out of frame (clipped by the stack) while the
    /// incoming card slides in from the opposite edge, with no cross-fade.
    static func riffleSlide(direction: RiffleDirection) -> AnyTransition {
        let insertEdge: Edge = direction == .forward ? .bottom : .top
        let removeEdge: Edge = direction == .forward ? .top : .bottom
        return .asymmetric(
            insertion: .move(edge: insertEdge),
            removal: .move(edge: removeEdge)
        )
    }

    /// The signature widget swap: the deck pushes vertically — the outgoing card
    /// slides out one edge while the incoming card slides in from the opposite
    /// edge, both scaling down slightly so each card reads as being "pressed down"
    /// and released as it settles. Direction follows navigation.
    static func rifflePush(direction: RiffleDirection) -> AnyTransition {
        let insertEdge: Edge = direction == .forward ? .bottom : .top
        let removeEdge: Edge = direction == .forward ? .top : .bottom
        let press = AnyTransition.scale(scale: 0.9)
        return .asymmetric(
            insertion: .move(edge: insertEdge).combined(with: press),
            removal: .move(edge: removeEdge).combined(with: press)
        )
    }
}
