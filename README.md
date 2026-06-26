# Riffle

**An Apple Smart Stack, for the inside of your app.**

You know the Smart Stack on the Home Screen: a single slot that holds a deck of
widgets, keeps the most relevant one on top, rotates through them on its own, and
lets you flick up and down to see the rest. Riffle brings that exact behavior
*inside* your SwiftUI app — one card slot that surfaces your highest-priority
card, auto-rotates through the eligible ones, and lets the user swipe vertically
to cycle, complete with the peeking deck and a configurable flip transition.

![Riffle in action](Examples/example.gif)

It is content-agnostic: use the built-in card layout or drop in your own views.
Typical cards are "Upgrade to Pro" upsells, "Rate this app" prompts, feature
tips, announcements, and seasonal offers — the things you'd otherwise scatter
across the UI as one-off banners.

Like the system Smart Stack, the card on top is the one that matters most right
now. The difference: *you* define "most" with `priority` and `shown(when:)`, so
the rotation is deterministic and testable instead of a black box.

- Pure SwiftUI, zero dependencies
- Swift 6 language mode, strict-concurrency clean
- Accessible by default: VoiceOver adjustable, honors Reduce Motion, Dynamic Type friendly

## How it maps to the Smart Stack

| Smart Stack | Riffle |
|-------------|--------|
| A stack of widgets in one slot | A `RiffleStack` of cards in one `frame` |
| Most relevant widget on top | Highest `priority`, eligible card on top |
| Smart Rotate through the day | `riffleAutoAdvance(.seconds(_:))` |
| Swipe up/down to flip through | Vertical drag to cycle cards |
| Widgets peeking at the edges | `riffleStackDepth(_:)` deck peek |
| Widget shows only when relevant | `shown(when:)` eligibility gate |

## Requirements

| Platform | Minimum |
|----------|---------|
| iOS      | 17 |
| macOS    | 14 |
| tvOS     | 17 |
| watchOS  | 10 |
| visionOS | 1 |

## Installation

Swift Package Manager. In Xcode choose *File ▸ Add Package Dependencies…* and
enter the repository URL, or add it to your `Package.swift`:

```swift
.package(url: "https://github.com/kempsu/Riffle.git", from: "1.0.0")
```

Then add `"Riffle"` to your target's dependencies.

## Usage

```swift
import Riffle
import SwiftUI

struct PromosView: View {
    let entitlements: Entitlements
    let engagement: Engagement
    let review: ReviewState

    var body: some View {
        RiffleStack {
            RiffleCard(id: "pro") {
                ProUpsellView()
            }
            .priority(.high)
            .shown(when: !entitlements.isPro)

            RiffleCard(id: "rate") {
                RateAppView()
            }
            .shown(when: engagement.daysActive >= 7 && !review.hasRated)

            RiffleCard(id: "tip-gestures") {
                TipView(text: "Swipe down to switch cards")
            }
        }
        .riffleTransition(.flip)
        .riffleAutoAdvance(.seconds(6))
        .rifflePausesOnInteraction(true)
        .riffleLoops(true)
        .riffleIndicator(.bars)
        .riffleStackDepth(2)
        .frame(height: 120)
    }
}
```

Cards are filtered by eligibility (`shown(when:)`) and ordered by priority,
highest first, preserving declaration order within a priority. When no card is
eligible, the stack renders nothing — zero size, no chrome — so it's safe to
leave in a layout permanently and let eligibility decide whether anything shows.

A runnable iOS demo app lives in [`Examples/RiffleDemo`](Examples/RiffleDemo),
with live controls for eligibility, looping, auto-advance, stack depth, and
transition.

### Styling cards

There are two ways to supply a card: the built-in layout, or your own view. You
can mix both in the same stack.

#### Built-in card

For the common upsell, prompt, or tip, use the `RiffleCard(id:title:…)`
initializer. It renders a `RiffleStandardCard` whose padding, corner radius, and
text scale to the stack's height, so you only choose the content and background:

```swift
RiffleCard(id: "pro",
           title: "Upgrade to Pro",
           message: "Unlock everything.",
           systemImage: "sparkles",              // leading SF Symbol badge
           background: .gradient(light: [.pink, .orange], dark: [.purple, .indigo]),
           accessory: .chevron,                  // trailing glyph; .none or .symbol("…")
           action: { showPaywall() },            // makes the whole card tappable
           onDismiss: { hasRated = true })        // adds a ✕ close button
```

`RiffleCardBackground` is the main styling knob. Every variant accepts an optional
light/dark pair:

```swift
.color(.orange)
.color(light: .orange, dark: .brown)
.gradient([.pink, .orange])
.gradient(light: [.pink, .orange], dark: [.purple, .indigo])
.image(Image("hero"))                       // full-bleed, cropped to fill
RiffleCardBackground(.ultraThinMaterial)    // any ShapeStyle
```

Add a decorative "sticker" with `RiffleCardAccent`, which controls its size,
corner, offset, rotation, and opacity:

```swift
accent: RiffleCardAccent(Image("badge"), size: 80,
                         alignment: .topTrailing, rotation: .degrees(-12))
```

#### Custom views

For anything else, supply your own view. Riffle sizes it to the stack's `frame`,
then animates the transition, the deck, and the optional shadow. It imposes no
background, corner radius, or clipping, so the look is entirely yours:

```swift
RiffleCard(id: "promo") {
    MyPromoView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)   // fill the card
        .background(.blue.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
}
.onTap { showPaywall() }     // optional whole-card tap
```

Three things to get right with a custom view:

- Fill the frame with `maxWidth`/`maxHeight: .infinity`, or the view floats inside
  the card slot instead of filling it.
- Apply your own corner radius and `clipShape` — the stack won't round it for you.
- `riffleCardShadow` traces the view's rendered alpha, so give it an opaque
  background and clip shape for the shadow to read as a card rather than outlining
  its text.

### Configuration

Every option is a modifier, so settings compose and can be set at any level of
the view tree.

| Modifier | Default | Description |
|----------|---------|-------------|
| `riffleTransition(_:)` | `.flip` | Front-card animation: `.flip`, `.slide`, `.push`, `.fade`, `.scale`, `.custom(_:)`. |
| `riffleAutoAdvance(_:)` | `.off` | Rotate every *n* seconds, or `.off`. |
| `rifflePausesOnInteraction(_:)` | `true` | Pause auto-advance while interacting and for one interval afterward. |
| `riffleLoops(_:)` | `true` | Wrap around the ends, or stop at the first and last cards. |
| `riffleIndicator(_:)` | `.dots` | Page indicator: `.none`, `.dots`, `.bars`, `.custom(_:)`. |
| `riffleIndicatorTint(_:)` | adaptive | Indicator color. `nil` adapts to the content behind it. |
| `riffleStackDepth(_:)` | `2` | How many cards peek behind the front, like a deck. `0` shows only the front. |
| `riffleCardShadow(_:)` | `true` | Draw a soft drop shadow under the front card. |

Auto-advance pauses while the scene is inactive and stops when the stack leaves
the screen, so it never burns a timer in the background.

### Priority

`RifflePriority` is backed by an `Int` raw value, so you can define your own
levels alongside `.low`, `.normal`, and `.high`:

```swift
extension RifflePriority {
    static let critical = RifflePriority(rawValue: 1500)
}
```

## Accessibility

The stack is a VoiceOver adjustable element: swipe up and down to move between
cards. It reports its position as "Card 2 of 4", and degrades motion to a
cross-fade when Reduce Motion is enabled. Built-in indicators scale with
Dynamic Type.

Manual swipe navigation uses a vertical drag (iOS, macOS, watchOS, visionOS). On
tvOS, cards auto-advance and VoiceOver can cycle them via the adjustable action,
but there is no remote-driven manual navigation in v1.

## Roadmap

Planned for later releases:

- Data-driven `RiffleStack(_:content:)` over a collection of `RiffleItem`.
- Frequency capping and snooze ("show at most N times", "remind me later") with a pluggable persistence store.
- Lifecycle callbacks: `onShow`, `onDismiss`, `onSelect`.
- A horizontal transition option and a configurable swipe axis.
- Relevance signals beyond static priority, such as recency and last-shown time — closing the loop on true Smart Rotate.

## More from Appgineering

If Riffle is useful to you, check out our other apps:

- [Appgineering on the App Store](https://apps.apple.com/us/developer/appgineering-gbr/id1785233826)
- [appgineering.com](https://appgineering.com)
- [neitola.dev](https://neitola.dev) — the maintainer's personal site

## License

MIT. See [LICENSE](LICENSE).
</content>
</invoke>
