# ``Riffle``

A widget-style rotating card stack for SwiftUI.

## Overview

Riffle shows one card at a time from a prioritized set, auto-rotates between
them, lets the user swipe vertically to cycle, and animates each change with a
configurable transition. It is content-agnostic: you supply the card views.
Typical content includes upsells, review prompts, feature tips, and
announcements.

```swift
RiffleStack {
    RiffleCard(id: "pro") { ProUpsellView() }
        .priority(.high)
        .shown(when: !entitlements.isPro)

    RiffleCard(id: "rate") { RateAppView() }
        .shown(when: engagement.daysActive >= 7)

    RiffleCard(id: "tip") { TipView(text: "Swipe down to switch cards") }
}
.riffleTransition(.flip)
.riffleAutoAdvance(.seconds(6))
.riffleIndicator(.bars)
.riffleStackDepth(2)
.frame(height: 120)
```

Cards are filtered by eligibility and ordered by priority. When no card is
eligible, the stack renders nothing.

## Topics

### Essentials

- <doc:GettingStarted>
- ``RiffleStack``
- ``RiffleCard``

### Ordering

- ``RifflePriority``

### Appearance and behavior

- ``RiffleTransition``
- ``RiffleAdvance``
- ``RiffleIndicator``
