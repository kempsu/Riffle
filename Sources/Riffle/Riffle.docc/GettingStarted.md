# Getting Started

Add a rotating card stack to your app in a few lines.

## Add the package

In Xcode choose *File ▸ Add Package Dependencies…* and enter the repository URL,
or add it to your `Package.swift`:

```swift
.package(url: "https://github.com/kempsu/Riffle.git", from: "1.0.0")
```

Then add `"Riffle"` to your target's dependencies.

## Build a stack

Declare your cards inside a ``RiffleStack``. Each ``RiffleCard`` needs a stable
`id` and supplies its own content. Use ``RiffleCard/priority(_:)`` to influence
ordering and ``RiffleCard/shown(when:)`` to gate eligibility.

```swift
import Riffle
import SwiftUI

struct PromosView: View {
    let entitlements: Entitlements
    let engagement: Engagement

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
            .shown(when: engagement.daysActive >= 7)

            RiffleCard(id: "tip") {
                TipView(text: "Swipe down to switch cards")
            }
        }
        .riffleAutoAdvance(.seconds(6))
        .riffleIndicator(.bars)
        .frame(height: 120)
    }
}
```

## Style your cards

There are two ways to supply a card, and you can mix both in the same stack.

For the common upsell, prompt, or tip, use the `RiffleCard(id:title:…)`
initializer. It renders a ``RiffleStandardCard`` whose padding, corner radius,
and text scale to the stack's height, so you only choose the content and
background:

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

``RiffleCardBackground`` is the main styling knob. Every variant accepts an
optional light/dark pair:

```swift
.color(.orange)
.color(light: .orange, dark: .brown)
.gradient([.pink, .orange])
.gradient(light: [.pink, .orange], dark: [.purple, .indigo])
.image(Image("hero"))                       // full-bleed, cropped to fill
RiffleCardBackground(.ultraThinMaterial)    // any ShapeStyle
```

Add a decorative "sticker" with ``RiffleCardAccent``, which controls its size,
corner, offset, rotation, and opacity:

```swift
accent: RiffleCardAccent(Image("badge"), size: 80,
                         alignment: .topTrailing, rotation: .degrees(-12))
```

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

- Fill the frame with `maxWidth`/`maxHeight: .infinity`, or the view floats
  inside the card slot instead of filling it.
- Apply your own corner radius and `clipShape` — the stack won't round it for you.
- `riffleCardShadow(_:)` traces the view's rendered alpha, so give
  it an opaque background and clip shape for the shadow to read as a card rather
  than outlining its text.

## Configure behavior

Every option is set with a modifier, so settings compose and can live at any
level of the view tree:

- `riffleTransition(_:)` — the front-card animation. `.flip` is the default.
- `riffleAutoAdvance(_:)` — rotate every *n* seconds, or `.off`.
- `rifflePausesOnInteraction(_:)` — hold the timer while the user interacts.
- `riffleLoops(_:)` — wrap around the ends, or stop.
- `riffleIndicator(_:)` — the page indicator style.
- `riffleIndicatorTint(_:)` — the indicator color; `nil` adapts to the content.
- `riffleStackDepth(_:)` — how many cards peek behind the front.
- `riffleCardShadow(_:)` — draw a soft drop shadow under the front card.

## Accessibility

The stack is a VoiceOver adjustable element: swipe up and down to move between
cards. It reports its position as "Card 2 of 4", and degrades every transition
to a cross-fade when Reduce Motion is enabled.
