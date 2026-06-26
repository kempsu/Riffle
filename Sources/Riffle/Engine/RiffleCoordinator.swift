import SwiftUI

/// The engine behind a ``RiffleStack``.
///
/// Owns the ordered, eligible card set, the current index, the auto-advance
/// timer, looping behavior, and the interaction lifecycle. All view-independent
/// logic lives here so it can be unit tested without rendering.
@MainActor
@Observable
final class RiffleCoordinator {
    /// The identifiers of the eligible cards, in display order.
    private(set) var orderedIDs: [AnyHashable] = []

    /// The index of the front card within `orderedIDs`.
    private(set) var index: Int = 0

    /// A monotonic counter that moves by the navigation direction on every change,
    /// without wrapping. `step % count == index`, but because it never wraps it gives
    /// each visible deck position a stable identity across a loop, so the deck slides
    /// rather than cross-sliding the wrapping card. Used only by the view layer.
    private(set) var step: Int = 0

    /// The direction of the most recent navigation, used for asymmetric transitions.
    private(set) var direction: RiffleDirection = .forward

    /// Whether a drag interaction is currently in progress.
    private(set) var isInteracting: Bool = false

    /// Bumped on every interaction. Exposed so tests can observe timer resets.
    private(set) var interactionGeneration: Int = 0

    var loops: Bool = true
    var autoAdvance: RiffleAdvance = .off
    var pausesOnInteraction: Bool = true
    private(set) var isActive: Bool = true

    private var currentID: AnyHashable?
    private var advanceTask: Task<Void, Never>?

    /// The number of eligible cards.
    var count: Int { orderedIDs.count }

    /// Whether the auto-advance timer is currently scheduled. Exposed for tests.
    var isTimerScheduled: Bool { advanceTask != nil }

    // MARK: - Ordering

    /// Filters out ineligible cards and sorts the rest by priority descending,
    /// preserving declaration order within a priority (a stable sort).
    static func order(_ cards: [ResolvedCard]) -> [ResolvedCard] {
        cards
            .filter(\.isEligible)
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.priority == rhs.element.priority {
                    return lhs.offset < rhs.offset
                }
                return lhs.element.priority > rhs.element.priority
            }
            .map(\.element)
    }

    // MARK: - Reconciliation

    /// Updates the coordinator with the latest ordered identifiers and
    /// configuration, preserving the currently shown card across reorders.
    func reconcile(orderedIDs ids: [AnyHashable],
                   loops: Bool,
                   autoAdvance: RiffleAdvance,
                   pausesOnInteraction: Bool) {
        self.loops = loops
        self.autoAdvance = autoAdvance
        self.pausesOnInteraction = pausesOnInteraction
        self.orderedIDs = ids

        let oldIndex = index
        if let currentID, let position = ids.firstIndex(of: currentID) {
            index = position
        } else if ids.isEmpty {
            index = 0
            currentID = nil
        } else {
            index = min(max(index, 0), ids.count - 1)
            currentID = ids[index]
        }
        // Keep step congruent with index across reordering. A card-set change is not a
        // smooth advance, so an occasional discontinuity here is acceptable.
        step += index - oldIndex
        syncTimer()
    }

    // MARK: - Navigation

    /// Advances to the next card, wrapping when `loops` is `true`.
    func goToNext() {
        guard !orderedIDs.isEmpty else { return }
        direction = .forward
        if index < orderedIDs.count - 1 {
            index += 1
            step += 1
        } else if loops {
            index = 0
            step += 1
        }
        currentID = orderedIDs[index]
    }

    /// Returns to the previous card, wrapping when `loops` is `true`.
    func goToPrevious() {
        guard !orderedIDs.isEmpty else { return }
        direction = .backward
        if index > 0 {
            index -= 1
            step -= 1
        } else if loops {
            index = orderedIDs.count - 1
            step -= 1
        }
        currentID = orderedIDs[index]
    }

    /// Jumps directly to `target` when it is a valid, different index.
    func go(to target: Int) {
        guard orderedIDs.indices.contains(target), target != index else { return }
        direction = target > index ? .forward : .backward
        step += target - index
        index = target
        currentID = orderedIDs[index]
    }

    /// The action performed when the auto-advance timer fires. Stops the timer
    /// once it reaches the last card while not looping.
    func tick() {
        guard orderedIDs.count > 1 else { return }
        if !loops && index == orderedIDs.count - 1 {
            stopTimer()
            return
        }
        goToNext()
    }

    // MARK: - Interaction lifecycle

    /// Begins a drag interaction and resets the timer. When `pausesOnInteraction`
    /// is `true` the reset resolves to a pause for the duration of the gesture;
    /// when `false` the timer keeps running from a fresh interval.
    func beginInteraction() {
        isInteracting = true
        interactionGeneration += 1
        resetTimer()
    }

    /// Ends a drag interaction, navigating based on the drag distance, then
    /// resets the timer for one full interval afterward.
    func endInteraction(translation: CGFloat = 0, threshold: CGFloat = 44) {
        if translation <= -threshold {
            goToNext()
        } else if translation >= threshold {
            goToPrevious()
        }
        isInteracting = false
        interactionGeneration += 1
        resetTimer()
    }

    /// Registers a discrete interaction, such as an indicator tap, and resets the
    /// timer.
    func registerInteraction() {
        interactionGeneration += 1
        resetTimer()
    }

    // MARK: - Scene phase

    /// Reflects whether the owning scene is active. Inactive scenes pause the timer.
    func setActive(_ active: Bool) {
        isActive = active
        syncTimer()
    }

    /// Cancels the auto-advance timer. Called when the stack disappears.
    func stop() {
        stopTimer()
    }

    // MARK: - Timer

    private var shouldAutoAdvance: Bool {
        guard let interval = autoAdvance.interval, interval > 0 else { return false }
        // An interaction only suspends the timer when pausing is enabled.
        return orderedIDs.count > 1 && isActive && !(isInteracting && pausesOnInteraction)
    }

    /// Starts the timer if it should be running and isn't already; otherwise
    /// stops it. Safe to call on every update without disturbing the timer phase.
    private func syncTimer() {
        if shouldAutoAdvance {
            if advanceTask == nil { startTimer() }
        } else {
            stopTimer()
        }
    }

    /// Restarts the timer from a full interval, or stops it when it should not run.
    private func resetTimer() {
        if shouldAutoAdvance {
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        guard let interval = autoAdvance.interval, interval > 0 else { return }
        advanceTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                if Task.isCancelled { return }
                guard let self else { return }
                self.tick()
            }
        }
    }

    private func stopTimer() {
        advanceTask?.cancel()
        advanceTask = nil
    }
}
