import Testing
import SwiftUI
@testable import Riffle

@MainActor
private func makeCard(_ id: String, _ priority: RifflePriority = .normal, eligible: Bool = true) -> ResolvedCard {
    ResolvedCard(id: AnyHashable(id), priority: priority, isEligible: eligible, content: AnyView(EmptyView()))
}

private func ids(_ cards: [ResolvedCard]) -> [String] {
    cards.compactMap { $0.id.base as? String }
}

private func aids(_ values: String...) -> [AnyHashable] {
    values.map { AnyHashable($0) }
}

@MainActor
@Suite("RiffleCoordinator")
struct RiffleCoordinatorTests {

    @Test("Filters out ineligible cards")
    func filtersIneligible() {
        let ordered = RiffleCoordinator.order([
            makeCard("a"),
            makeCard("b", eligible: false),
            makeCard("c")
        ])
        #expect(ids(ordered) == ["a", "c"])
    }

    @Test("Sorts by priority descending, stable within a priority")
    func stableSort() {
        let ordered = RiffleCoordinator.order([
            makeCard("a", .normal),
            makeCard("b", .high),
            makeCard("c", .normal),
            makeCard("d", .high),
            makeCard("e", .low)
        ])
        // high (b, d in declaration order), then normal (a, c), then low (e).
        #expect(ids(ordered) == ["b", "d", "a", "c", "e"])
    }

    @Test("Renders nothing when no card is eligible")
    func emptyWhenNoneEligible() {
        let ordered = RiffleCoordinator.order([
            makeCard("a", eligible: false),
            makeCard("b", eligible: false)
        ])
        #expect(ordered.isEmpty)
    }

    @Test("A card removed by ineligibility returns when it becomes eligible again")
    func restoresReeligibleCard() {
        let c = RiffleCoordinator()
        // Start with all three eligible, viewing the front card.
        c.reconcile(orderedIDs: aids("pro", "rate", "tip"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        #expect(c.orderedIDs == aids("pro", "rate", "tip"))

        // "rate" becomes ineligible (e.g. the user rated): it drops out.
        c.reconcile(orderedIDs: aids("pro", "tip"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        #expect(c.orderedIDs == aids("pro", "tip"))

        // Toggling it back to eligible restores it to the rotation.
        c.reconcile(orderedIDs: aids("pro", "rate", "tip"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        #expect(c.orderedIDs == aids("pro", "rate", "tip"))
    }

    @Test("Next and previous move through the cards")
    func nextPrevious() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b", "c"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        #expect(c.index == 0)
        c.goToNext(); #expect(c.index == 1)
        c.goToNext(); #expect(c.index == 2)
        c.goToPrevious(); #expect(c.index == 1)
    }

    @Test("Looping wraps at the ends")
    func loopingWraps() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b", "c"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        c.goToPrevious(); #expect(c.index == 2)   // wrap to the end
        c.goToNext(); #expect(c.index == 0)        // wrap to the start
    }

    @Test("Non-looping stops at the ends")
    func nonLoopingStops() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b", "c"), loops: false, autoAdvance: .off, pausesOnInteraction: true)
        c.goToPrevious(); #expect(c.index == 0)    // stays at the start
        c.go(to: 2)
        c.goToNext(); #expect(c.index == 2)        // stays at the end
    }

    @Test("Tick advances like the auto-advance timer")
    func tickAdvances() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b", "c"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        c.tick(); #expect(c.index == 1)
        c.tick(); #expect(c.index == 2)
        c.tick(); #expect(c.index == 0)            // wraps
    }

    @Test("Tick stops at the end when not looping")
    func tickStopsAtEndWithoutLooping() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b"), loops: false, autoAdvance: .seconds(5), pausesOnInteraction: true)
        #expect(c.isTimerScheduled)
        c.tick(); #expect(c.index == 1)
        c.tick(); #expect(c.index == 1)            // no further advance
        #expect(!c.isTimerScheduled)               // timer stops at the end
        c.stop()
    }

    @Test("Auto-advance schedules a timer only with multiple cards and an interval")
    func timerScheduling() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a"), loops: true, autoAdvance: .seconds(5), pausesOnInteraction: true)
        #expect(!c.isTimerScheduled)               // single card: no timer

        c.reconcile(orderedIDs: aids("a", "b"), loops: true, autoAdvance: .seconds(5), pausesOnInteraction: true)
        #expect(c.isTimerScheduled)

        c.reconcile(orderedIDs: aids("a", "b"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        #expect(!c.isTimerScheduled)               // off: no timer
        c.stop()
    }

    @Test("Interaction resets the timer and pauses when configured")
    func interactionResetsTimer() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b"), loops: true, autoAdvance: .seconds(5), pausesOnInteraction: true)
        #expect(c.isTimerScheduled)
        let generation = c.interactionGeneration

        c.beginInteraction()
        #expect(c.interactionGeneration > generation)
        #expect(!c.isTimerScheduled)               // paused during interaction

        c.endInteraction(translation: 0)
        #expect(c.isTimerScheduled)                // resumed afterward
        c.stop()
    }

    @Test("Non-pausing interaction keeps the timer running")
    func nonPausingInteractionKeepsTimer() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b"), loops: true, autoAdvance: .seconds(5), pausesOnInteraction: false)
        #expect(c.isTimerScheduled)

        c.beginInteraction()
        #expect(c.isTimerScheduled)                // not paused during interaction
        c.endInteraction(translation: 0)
        #expect(c.isTimerScheduled)
        c.stop()
    }

    @Test("A non-finite interval does not schedule a timer")
    func nonFiniteIntervalIsInert() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b"), loops: true, autoAdvance: .seconds(.infinity), pausesOnInteraction: true)
        #expect(!c.isTimerScheduled)
        c.reconcile(orderedIDs: aids("a", "b"), loops: true, autoAdvance: .seconds(.nan), pausesOnInteraction: true)
        #expect(!c.isTimerScheduled)
    }

    @Test("Scene phase inactivity pauses the timer")
    func scenePhasePauses() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b"), loops: true, autoAdvance: .seconds(5), pausesOnInteraction: true)
        #expect(c.isTimerScheduled)
        c.setActive(false)
        #expect(!c.isTimerScheduled)
        c.setActive(true)
        #expect(c.isTimerScheduled)
        c.stop()
    }

    @Test("Reconcile preserves the visible card across reordering")
    func preservesSelectionAcrossReorder() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b", "c"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        c.goToNext()                                // now on "b"
        #expect(c.index == 1)
        c.reconcile(orderedIDs: aids("c", "b", "a"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        #expect(c.index == 1)                       // still "b", now at position 1
        c.reconcile(orderedIDs: aids("c", "a", "b"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        #expect(c.index == 2)                       // still "b", now at position 2
    }

    @Test("Empty set leaves navigation as a no-op")
    func emptySetNoOp() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: [], loops: true, autoAdvance: .seconds(5), pausesOnInteraction: true)
        #expect(c.count == 0)
        #expect(!c.isTimerScheduled)
        c.goToNext()
        #expect(c.index == 0)
    }

    @Test("Ending a drag navigates based on direction")
    func dragNavigation() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b", "c"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        c.beginInteraction()
        c.endInteraction(translation: -60)          // swipe up: next
        #expect(c.index == 1)
        c.beginInteraction()
        c.endInteraction(translation: 60)           // swipe down: previous
        #expect(c.index == 0)
    }

    @Test("A small drag does not change the card")
    func smallDragIsNoOp() {
        let c = RiffleCoordinator()
        c.reconcile(orderedIDs: aids("a", "b", "c"), loops: true, autoAdvance: .off, pausesOnInteraction: true)
        c.beginInteraction()
        c.endInteraction(translation: -10)          // below the threshold
        #expect(c.index == 0)
    }
}
