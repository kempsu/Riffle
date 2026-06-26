import SwiftUI

/// A widget-style rotating card stack.
///
/// `RiffleStack` shows one card at a time from a prioritized set, auto-rotates
/// between them, lets the user swipe vertically to cycle, and animates each
/// change with a configurable transition. It is content-agnostic: you supply the
/// card views. Tune behavior with the `riffle*` modifiers.
///
/// ```swift
/// RiffleStack {
///     RiffleCard(id: "pro") { ProUpsellView() }
///         .priority(.high)
///         .shown(when: !entitlements.isPro)
///     RiffleCard(id: "rate") { RateAppView() }
///         .shown(when: engagement.daysActive >= 7)
///     RiffleCard(id: "tip") { TipView(text: "Swipe down to switch cards") }
/// }
/// .riffleTransition(.flip)
/// .riffleAutoAdvance(.seconds(6))
/// .riffleIndicator(.bars)
/// .riffleStackDepth(2)
/// .frame(height: 120)
/// ```
///
/// When no cards are eligible the stack renders nothing.
///
/// - Note: Manual swipe navigation uses a vertical drag, so it is active on iOS,
///   macOS, watchOS, and visionOS. On tvOS, which has no touch input, cards still
///   auto-advance and VoiceOver users can move between them with the adjustable
///   action, but there is no remote-driven manual navigation in v1.
@MainActor
public struct RiffleStack: View {
    @Environment(\.riffleConfiguration) private var configuration
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var coordinator = RiffleCoordinator()

    private let cards: [ResolvedCard]

    /// The minimum height a card is laid out at. A host `frame` shorter than this clips
    /// the card rather than shrinking the layout below it, so cards never collapse.
    public static let minimumCardHeight: CGFloat = 48
    /// The minimum width a card is laid out at. A narrower host `frame` clips the card.
    public static let minimumCardWidth: CGFloat = 120

    /// Creates a stack from a declarative list of ``RiffleCard`` values.
    public init(@RiffleBuilder _ content: () -> RiffleContent) {
        self.cards = content().cards
    }

    public var body: some View {
        let ordered = RiffleCoordinator.order(cards)
        let key = SyncKey(
            ids: ordered.map(\.id),
            loops: configuration.loops,
            autoAdvance: configuration.autoAdvance,
            pauses: configuration.pausesOnInteraction
        )

        return content(ordered: ordered)
            .onChange(of: key, initial: true) { _, newKey in
                coordinator.reconcile(
                    orderedIDs: newKey.ids,
                    loops: configuration.loops,
                    autoAdvance: configuration.autoAdvance,
                    pausesOnInteraction: configuration.pausesOnInteraction
                )
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                coordinator.setActive(phase == .active)
            }
            .onDisappear { coordinator.stop() }
    }

    @ViewBuilder
    private func content(ordered: [ResolvedCard]) -> some View {
        if ordered.isEmpty {
            // Nothing eligible: render nothing, zero size, no chrome.
            EmptyView()
        } else {
            let count = ordered.count
            let i = min(max(coordinator.index, 0), count - 1)
            let visibleDepth = min(configuration.stackDepth, max(0, count - 1))

            GeometryReader { geo in
                // Same height the deck uses, so the indicator sits on the front card,
                // just above the (size-proportional) deck peek.
                let deckInset = RiffleDeck.deckInset(forHeight: geo.size.height, depth: visibleDepth)

                ZStack(alignment: .bottom) {
                    // The deck owns the live drag so a swipe re-renders only the cards,
                    // not this whole view (its ordering, indicator, geometry).
                    RiffleDeck(
                        ordered: ordered,
                        front: i,
                        step: coordinator.step,
                        transition: configuration.transition,
                        stackDepth: visibleDepth,
                        loops: configuration.loops,
                        reduceMotion: reduceMotion,
                        cardShadow: configuration.cardShadow,
                        coordinator: coordinator
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(Text("Card \(i + 1) of \(count)"))
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment:
                            coordinator.goToNext()
                            coordinator.registerInteraction()
                        case .decrement:
                            coordinator.goToPrevious()
                            coordinator.registerInteraction()
                        @unknown default:
                            break
                        }
                    }
                    .modifier(CardAccessibilityActions(
                        action: ordered[i].action,
                        onDismiss: ordered[i].onDismiss
                    ))

                    if count > 1 {
                        RiffleIndicatorView(
                            indicator: configuration.indicator,
                            count: count,
                            index: i,
                            tint: configuration.indicatorTint,
                            onSelect: { target in
                                coordinator.go(to: target)
                                coordinator.registerInteraction()
                            }
                        )
                        // Sit on the front card, above the deck peeking below it.
                        .padding(.bottom, 8 + deckInset)
                        .accessibilityHidden(true)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private struct SyncKey: Equatable {
        let ids: [AnyHashable]
        let loops: Bool
        let autoAdvance: RiffleAdvance
        let pauses: Bool
    }
}

/// The card layer of a ``RiffleStack``. It owns the live drag, so a manual swipe
/// re-renders only the cards. A drag plays an interactive version of the active
/// transition that tracks the finger and can be aborted; releasing past a third of
/// a page (or a flick) commits, otherwise it snaps back.
@MainActor
private struct RiffleDeck: View {
    let ordered: [ResolvedCard]
    let front: Int
    let step: Int
    let transition: RiffleTransition
    let stackDepth: Int
    let loops: Bool
    let reduceMotion: Bool
    let cardShadow: Bool
    let coordinator: RiffleCoordinator

    /// Live drag translation, clamped to one page of travel.
    @State private var drag: CGFloat = 0
    /// True while a drag (and its settle) is in flight, so the cards render as the
    /// interactive transition and the identity-change transition is suppressed.
    @State private var dragging = false

    private var settle: Animation {
        reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.42, dampingFraction: 0.78)
    }

    private var style: InteractiveStyle {
        if reduceMotion { return .fade }
        switch transition {
        case .push: return .push
        case .slide: return .slide
        case .flip: return .flip
        case .scale: return .scale
        case .fade, .custom: return .fade
        }
    }

    /// The smallest size a card is laid out at. Below this the deck renders at the floor
    /// and the host frame clips it, so the layout never collapses or overlaps.
    static let minHeight = RiffleStack.minimumCardHeight
    static let minWidth = RiffleStack.minimumCardWidth

    /// Deck geometry scales with the card height so a short card peeks proportionally
    /// instead of having a fixed inset eat most of it. Tuned so a ~104pt card peeks 8pt.
    static func peekStep(forHeight height: CGFloat) -> CGFloat {
        min(8, max(3, max(height, minHeight) * 0.077))
    }
    /// How far the deck reserves below the front card for the given height and depth.
    static func deckInset(forHeight height: CGFloat, depth: Int) -> CGFloat {
        CGFloat(depth) * peekStep(forHeight: height)
    }
    /// How much narrower each successive deck card is, per side.
    static func sideInset(forHeight height: CGFloat) -> CGFloat {
        peekStep(forHeight: height) * 1.5
    }

    var body: some View {
        GeometryReader { geo in
            // Enforce a minimum so cards stay laid out correctly; a smaller host frame
            // clips the result rather than collapsing the layout.
            let page = max(geo.size.height, Self.minHeight)
            let width = max(geo.size.width, Self.minWidth)

            // One renderer for every depth: at depth 0 the window is just the front and
            // its neighbours, and the configured transition slides/flips them; with a
            // deck, the same model adds the peeking cards.
            unifiedDeck(page: page, width: width)
                .frame(width: width, height: page, alignment: .top)
                .clipped()
                .contentShape(Rectangle())
                .gesture(dragGesture(page: page))
                .modifier(MinimumSizeWarning(size: geo.size))
        }
    }

    // MARK: Unified deck

    /// One coherent stack: every visible card is rendered exactly once and positioned
    /// by its distance from the front, so there is no separate "deck" copy of the
    /// incoming card. A drag advances `dp` continuously; a programmatic change shifts
    /// each card's slot and the positions interpolate (no snap, no duplicate peek).
    @ViewBuilder
    private func unifiedDeck(page: CGFloat, width: CGFloat) -> some View {
        let peekStep = Self.peekStep(forHeight: page)
        let sideInset = Self.sideInset(forHeight: page)
        let deckInset = CGFloat(stackDepth) * peekStep
        let bodyH = max(page - deckInset, 1)
        let dp = dragging ? -drag / page : 0

        ZStack(alignment: .top) {
            // Drawn back-to-front (highest offset first) so the front card sits on top
            // and the leaving card slides up over the deck.
            ForEach(stackWindow().reversed()) { item in
                stackCard(item, pos: CGFloat(item.offset) - dp,
                          page: page, width: width, bodyH: bodyH,
                          peekStep: peekStep, sideInset: sideInset)
            }
        }
        .frame(width: width, height: page, alignment: .top)
    }

    private func stackCard(_ item: StackItem, pos: CGFloat,
                           page: CGFloat, width: CGFloat, bodyH: CGFloat,
                           peekStep: CGFloat, sideInset: CGFloat) -> some View {
        item.content
            .modifier(StackCardEffect(pos: pos, depth: stackDepth, page: page,
                                      width: width, bodyH: bodyH,
                                      sideInset: sideInset, peekStep: peekStep,
                                      style: style, cardShadow: cardShadow))
            // Structurally stable: the tap is always attached (no `if action`), gated in
            // the closure. A branch here would change the view's structure as a card
            // moves to/from the front, resetting its identity and snapping the animation.
            // Only the front card is hit-testable (see StackCardEffect), so deck cards
            // ignore taps regardless.
            .onTapGesture {
                guard item.offset == 0, let action = item.action else { return }
                coordinator.registerInteraction()
                action()
            }
            .id(item.id)
            // Animate this card's own position. On a programmatic advance `pos` changes
            // by one slot and springs to its new place; during a drag `pos` tracks the
            // finger, so suppress the implicit animation and let the drag drive it.
            .animation(dragging ? nil : settle, value: pos)
    }

    /// A card to draw, with its offset from the front (0 = front, 1… = deck, -1 = the
    /// just-left card). `id` is the monotonic logical index (`step + offset`): a card
    /// sliding one slot keeps its id, while the wrapping card's leaving and re-entering
    /// copies get distinct ids — so the deck slides instead of cross-sliding one card.
    private struct StackItem: Identifiable {
        let id: Int
        let offset: Int
        let content: AnyView
        let action: (() -> Void)?
    }

    private func stackWindow() -> [StackItem] {
        let count = ordered.count
        guard count > 0 else { return [] }
        var items: [StackItem] = []
        for offset in -1...(stackDepth + 1) {
            let raw = front + offset
            let idx: Int
            if raw >= 0 && raw < count {
                idx = raw
            } else if loops {
                idx = ((raw % count) + count) % count
            } else {
                continue
            }
            let card = ordered[idx]
            items.append(StackItem(id: step + offset, offset: offset, content: card.content, action: card.action))
        }
        return items
    }

    // MARK: Neighbours

    private func nextIndex() -> Int? {
        if front < ordered.count - 1 { return front + 1 }
        return loops ? 0 : nil
    }

    private func previousIndex() -> Int? {
        if front > 0 { return front - 1 }
        return loops ? ordered.count - 1 : nil
    }

    // MARK: Gesture

    private func dragGesture(page: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if !coordinator.isInteracting { coordinator.beginInteraction() }
                dragging = true
                drag = clampedDrag(value.translation.height, page: page)
            }
            .onEnded { value in endDrag(value: value, page: page) }
    }

    /// Clamps the live drag to one page, rubber-banding past it and when no card
    /// exists in the drag direction.
    private func clampedDrag(_ raw: CGFloat, page: CGFloat) -> CGFloat {
        let hasNext = nextIndex() != nil
        let hasPrev = previousIndex() != nil
        if (raw < 0 && !hasNext) || (raw > 0 && !hasPrev) { return raw * 0.25 }
        if raw < -page { return -page + (raw + page) * 0.25 }
        if raw > page { return page + (raw - page) * 0.25 }
        return raw
    }

    private func endDrag(value: DragGesture.Value, page: CGFloat) {
        let spring: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
        let predicted = value.predictedEndTranslation.height
        // Only commit in the direction currently shown, so dragging toward a card
        // and then back releases as an abort rather than flicking the other way.
        let goNext = drag < 0 && nextIndex() != nil
            && (drag <= -page * 0.3 || predicted <= -page * 0.6)
        let goPrev = drag > 0 && previousIndex() != nil
            && (drag >= page * 0.3 || predicted >= page * 0.6)

        if goNext {
            withAnimation(spring) { drag = -page } completion: { commit(.forward) }
        } else if goPrev {
            withAnimation(spring) { drag = page } completion: { commit(.backward) }
        } else {
            withAnimation(spring) { drag = 0 } completion: {
                dragging = false
                coordinator.endInteraction(translation: 0)
            }
        }
    }

    private func commit(_ direction: RiffleDirection) {
        // The committed card is already centred by the settle, so swap the index and
        // reset the drag without animating (no transition fires), then leave the
        // dragging state on the next runloop once that render has landed.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            if direction == .forward { coordinator.goToNext() } else { coordinator.goToPrevious() }
            drag = 0
        }
        coordinator.endInteraction(translation: 0)
        Task { @MainActor in dragging = false }
    }
}

/// Exposes the front card's tap and dismiss actions to VoiceOver. The deck combines
/// its children, which flattens any in-card buttons, so the card's actions are
/// surfaced here on the combined element instead.
private struct CardAccessibilityActions: ViewModifier {
    let action: (() -> Void)?
    let onDismiss: (() -> Void)?

    // Structurally stable: the same two modifiers are always applied (no `if`/`switch`
    // over the optionals). A structural change here would reset the deck's identity and
    // its @State on every front-card change, which silently disables all animation.
    func body(content: Content) -> some View {
        content
            .accessibilityAction { action?() }
            .accessibilityAction(named: Text("Dismiss")) { onDismiss?() }
    }
}

/// In DEBUG, warns once when the host frame is smaller than the minimum card size, so a
/// developer notices they've under-sized the stack (it still renders, clamped + clipped).
/// Compiles to a no-op in release.
private struct MinimumSizeWarning: ViewModifier {
    let size: CGSize

    func body(content: Content) -> some View {
        #if DEBUG
        let undersized = size.width < RiffleStack.minimumCardWidth
            || size.height < RiffleStack.minimumCardHeight
        content.onChange(of: undersized, initial: true) { _, isUndersized in
            if isUndersized {
                print("""
                ⚠️ Riffle: the host frame (\(Int(size.width))×\(Int(size.height))) is below the \
                minimum card size (\(Int(RiffleStack.minimumCardWidth))×\(Int(RiffleStack.minimumCardHeight))). \
                The card is clamped to the minimum and clipped to the frame — give it at least \
                that size.
                """)
            }
        }
        #else
        content
        #endif
    }
}

/// The interactive, finger-tracked counterpart of each built-in transition, applied
/// to the outgoing and incoming cards as a drag progresses from 0 to 1.
private enum InteractiveStyle { case push, slide, flip, scale, fade }

/// Places one card in the unified deck by its continuous position `pos`:
/// `0` is the front, `1…depth` are the deck slots (each narrower and a step lower),
/// negative values are the card leaving via the configured transition's exit, and
/// values past the deck are the card entering at the back.
///
/// Every transform is a single, structurally-stable chain of continuous functions of
/// `pos` — no `if`/`switch` over `pos`. That is essential: a branch would make SwiftUI
/// cross-fade (rather than slide) whenever an animation interpolates a card across the
/// `pos == 0` boundary, which is the "fade/pop" seen on commit and auto-advance.
private struct StackCardEffect: ViewModifier, Animatable {
    var pos: CGFloat
    let depth: Int
    let page: CGFloat
    let width: CGFloat
    let bodyH: CGFloat
    let sideInset: CGFloat
    let peekStep: CGFloat
    let style: InteractiveStyle
    let cardShadow: Bool

    nonisolated var animatableData: CGFloat {
        get { pos }
        set { pos = newValue }
    }

    func body(content: Content) -> some View {
        let d = CGFloat(depth)
        // Position within the visible deck: 0 = front, d = back slot (narrower + lower).
        let deckPos = max(0, min(pos, d))
        let widthInset = deckPos * sideInset

        // Distance outside the deck: above the front (exit) or below the back (enter).
        let exit = max(0, -pos)
        let enter = max(0, pos - d)
        let slide = style == .push || style == .slide
        // The entering card is animated by the transition only when it becomes the front
        // (no deck). With a deck, a brand-new back card simply fades into the back slot.
        let styledEnter = depth == 0 ? enter : 0
        let backEnter = depth == 0 ? 0 : enter
        let move = min(max(exit, styledEnter), 1)   // 0…1 progress of the styled move

        // Vertical: deck peek, plus a full-page travel for push/slide (up to leave, from
        // below to arrive). Clipping removes the off-screen portion.
        let translate = slide ? (styledEnter - exit) * page : 0
        let offsetY = deckPos * peekStep + translate

        // Cap just under 90°: a full edge-on rotation makes the perspective projection
        // matrix singular (SwiftUI logs "ignoring singular matrix"). The card is fully
        // faded by then, so the 2° shortfall is invisible.
        let angle = style == .flip ? max(-88, min(88, (Double(exit) - Double(styledEnter)) * 90)) : 0
        let scale = style == .scale ? 1 - move * 0.15 : 1
        // Non-sliding styles fade over their move; sliding stays opaque (clip hides the
        // off-screen part). A new back card fades in regardless of style.
        let opacity = Double((slide ? 1 : (1 - move)) * max(0, 1 - backEnter))

        let shadow = cardShadow ? 0.12 * max(0, 1 - 2 * Double(abs(pos))) : 0

        return content
            .frame(width: max(width - 2 * widthInset, 1), height: bodyH)
            .scaleEffect(scale)
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0),
                              anchor: .center, perspective: 0.5)
            .offset(y: offsetY)
            .opacity(opacity)
            .shadow(color: .black.opacity(shadow), radius: 5, y: 2)
            .allowsHitTesting(abs(pos) < 0.5)
            .accessibilityHidden(abs(pos) >= 0.5)
    }
}

#if DEBUG
private struct RiffleSampleCard: View {
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.gradient)
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .opacity(0.85)
            }
            .multilineTextAlignment(.center)
            .padding()
            .foregroundStyle(.white)
        }
    }
}

#Preview("Three cards") {
    RiffleStack {
        RiffleCard(id: "pro") {
            RiffleSampleCard(title: "Upgrade to Pro", subtitle: "Unlock everything", tint: .blue)
        }
        .priority(.high)

        RiffleCard(id: "rate") {
            RiffleSampleCard(title: "Enjoying the app?", subtitle: "Leave a quick review", tint: .green)
        }

        RiffleCard(id: "tip") {
            RiffleSampleCard(title: "Tip", subtitle: "Swipe down to switch cards", tint: .orange)
        }
    }
    .riffleAutoAdvance(.seconds(4))
    .riffleIndicator(.bars)
    .riffleStackDepth(2)
    .frame(height: 150)
    .padding()
}

#Preview("Single card, no chrome") {
    RiffleStack {
        RiffleCard(id: "only") {
            RiffleSampleCard(title: "Just one card", subtitle: "No indicator, no rotation", tint: .purple)
        }
    }
    .frame(height: 150)
    .padding()
}
#endif
