import Riffle
import SwiftUI

/// A widget-style rotating card stack built entirely from Riffle's built-in card.
/// Every card is a single `RiffleCard(...)` call: title, message, symbol, a
/// `RiffleCardBackground` (solid, gradient, or distinct light/dark variants), and a
/// tap/dismiss action. The controls below drive every option live.
struct ContentView: View {
    @State private var isPro = false
    @State private var hasRated = false
    @State private var autoAdvance = true
    @State private var interval = 5.0
    @State private var loops = true
    @State private var stackDepth = 2.0
    @State private var transition = DemoTransition.push
    @State private var indicator = DemoIndicator.dots
    @State private var indicatorColor = DemoIndicatorColor.adaptive
    @State private var extraCards = 0
    @State private var cardShadow = true
    @State private var dismissable = true
    @State private var showSticker = true
    @State private var stickerAngle = -12.0
    @State private var stickerSize = 72.0
    @State private var showImageCard = true
    @State private var showRateAlert = false
    @State private var showPaywall = false
    @State private var showWhatsNew = false
    @State private var darkMode = false
    @State private var lastAction = "—"

    /// A real method (not an inline closure) — passed to a card as `action: openWhatsNew`.
    private func openWhatsNew() {
        lastAction = "openWhatsNew() called"
        showWhatsNew = true
    }

    var body: some View {
        VStack(spacing: 0) {
            // Kept out of the ScrollView so its vertical swipe is not stolen by scrolling.
            RiffleStack {
                RiffleCard(id: "pro",
                           title: "Upgrade to Riffle Pro",
                           message: "Unlock limitless inspiration management.",
                           systemImage: "sparkles",
                           background: .gradient(light: [.pink, .orange], dark: [.purple, .indigo]),
                           // A decorative sticker (a license-free image bundled as an asset;
                           // see Assets.xcassets/DemoSticker). Size/corner/angle are tunable.
                           accent: showSticker
                               ? RiffleCardAccent(Image("DemoSticker"),
                                                  size: stickerSize,
                                                  alignment: .trailing,
                                                  offset: CGSize(width: -14, height: 0),
                                                  rotation: .degrees(stickerAngle))
                               : nil,
                           // Tapping opens a mock paywall; it only hides once subscribed.
                           action: { showPaywall = true; lastAction = "Tapped Upgrade" })
                    .priority(.high)
                    .shown(when: !isPro)

                RiffleCard(id: "rate",
                           title: "Enjoying Riffle?",
                           message: "Leave a review to help others discover it too.",
                           systemImage: "star.fill",
                           background: .gradient(light: [.yellow, .orange], dark: [.orange, .brown]),
                           // Tapping the card opens the rate prompt; it only hides once
                           // the user actually rates (see the .alert below).
                           action: { showRateAlert = true; lastAction = "Tapped Rate" },
                           // Providing onDismiss makes the card dismissable (the ✕ hides it).
                           onDismiss: dismissable ? { hasRated = true; lastAction = "Dismissed Rate" } : nil)
                    .shown(when: !hasRated)

                // A full-bleed image background, and the action is a method reference
                // (`openWhatsNew`) rather than an inline closure — it opens a sheet.
                RiffleCard(id: "featured",
                           title: "What's New",
                           message: "Tap to see the latest updates.",
                           systemImage: "photo.fill",
                           background: .image(Image("DemoHero")),
                           // A custom trailing accessory instead of the default chevron.
                           accessory: .symbol("arrow.up.right"),
                           action: openWhatsNew)
                    .shown(when: showImageCard)

                RiffleCard(id: "tip",
                           title: "Tip",
                           message: "Swipe down to switch cards.",
                           systemImage: "hand.draw",
                           background: .color(light: Color(white: 0.32), dark: Color(white: 0.22)))
                    .priority(.low)

                for index in 0..<extraCards {
                    let palette = ExtraCard.all[index % ExtraCard.all.count]
                    RiffleCard(id: "extra-\(index)",
                               title: palette.title,
                               message: "Card #\(index + 1) added at runtime.",
                               systemImage: palette.symbol,
                               background: palette.background,
                               action: { lastAction = "Tapped \(palette.title)" })
                }
            }
            .riffleTransition(transition.transition)
            .riffleAutoAdvance(autoAdvance ? .seconds(interval) : .off)
            .riffleLoops(loops)
            .riffleIndicator(indicator.indicator)
            .riffleIndicatorTint(indicatorColor.color)
            .riffleStackDepth(Int(stackDepth))
            .riffleCardShadow(cardShadow)
            .frame(height: 104)
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 32)

            ScrollView { controls }
        }
        .background((darkMode ? Color(white: 0.08) : Color(white: 0.92)).ignoresSafeArea())
        .preferredColorScheme(darkMode ? .dark : .light)
        // Mock "rate this app" prompt. Rating hides the card; "Not now" keeps it around.
        .alert("Rate Riffle", isPresented: $showRateAlert) {
            Button("Rate 5 stars") { hasRated = true; lastAction = "Rated ★★★★★" }
            Button("Not now", role: .cancel) { lastAction = "Rating dismissed" }
        } message: {
            Text("Enjoying the app? Leave a quick review to help others discover it.")
        }
        // Mock paywall. Subscribing hides the upsell card; "Maybe later" keeps it.
        .alert("Riffle Pro", isPresented: $showPaywall) {
            Button("Subscribe – $4.99/mo") { isPro = true; lastAction = "Subscribed to Pro" }
            Button("Maybe later", role: .cancel) { lastAction = "Paywall dismissed" }
        } message: {
            Text("Unlock limitless inspiration management, advanced themes, and more.")
        }
        // Presented by the openWhatsNew() method that the "What's New" card's action fires.
        .sheet(isPresented: $showWhatsNew) {
            NavigationStack {
                List {
                    Label("Image & gradient card backgrounds", systemImage: "photo")
                    Label("Sticker accents you can rotate and place", systemImage: "seal")
                    Label("Smooth deck transitions", systemImage: "rectangle.stack")
                }
                .navigationTitle("What's New")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showWhatsNew = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Demo Controls")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Last action: \(lastAction)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            Toggle("Dark mode", isOn: $darkMode)
            Divider()
            Toggle("Pro unlocked (hides the upsell card)", isOn: $isPro)
            Divider()
            Toggle("Already rated (hides the rating card)", isOn: $hasRated)
            Divider()
            Stepper("Extra cards: \(extraCards)", value: $extraCards, in: 0...6)
            Divider()
            Toggle("Auto-advance", isOn: $autoAdvance)
            if autoAdvance {
                labelledSlider("Interval", String(format: "%.0fs", interval)) {
                    Slider(value: $interval, in: 2...8, step: 1)
                }
            }
            Divider()
            Toggle("Loop at the ends", isOn: $loops)
            Divider()
            labelledSlider("Stack depth", "\(Int(stackDepth))") {
                Slider(value: $stackDepth, in: 0...2, step: 1)
            }
            Divider()
            Toggle("Card shadow", isOn: $cardShadow)
            Divider()
            Toggle("Rate card dismissable (shows the ✕)", isOn: $dismissable)
            Divider()
            Toggle("Pro card sticker accent", isOn: $showSticker)
            if showSticker {
                labelledSlider("Sticker angle", "\(Int(stickerAngle))°") {
                    Slider(value: $stickerAngle, in: -45...45, step: 1)
                }
                labelledSlider("Sticker size", "\(Int(stickerSize))") {
                    Slider(value: $stickerSize, in: 40...110, step: 1)
                }
            }
            Divider()
            Toggle("Show image-background card", isOn: $showImageCard)
            Divider()
            Picker("Transition", selection: $transition) {
                ForEach(DemoTransition.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.top, 12)
            Picker("Indicator", selection: $indicator) {
                ForEach(DemoIndicator.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.top, 8)
            Picker("Indicator color", selection: $indicatorColor) {
                ForEach(DemoIndicatorColor.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(indicator == .none)
            .padding(.top, 8)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(20)
    }

    private func labelledSlider(_ title: String, _ value: String, @ViewBuilder _ slider: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                Spacer()
                Text(value).monospacedDigit().foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            slider()
        }
    }
}

// MARK: - Demo option types

private enum DemoTransition: String, CaseIterable {
    case push, flip, slide, fade, scale

    var transition: RiffleTransition {
        switch self {
        case .push: .push
        case .flip: .flip
        case .slide: .slide
        case .fade: .fade
        case .scale: .scale
        }
    }
}

private enum DemoIndicator: String, CaseIterable {
    case dots, bars, none

    var indicator: RiffleIndicator {
        switch self {
        case .dots: .dots
        case .bars: .bars
        case .none: .none
        }
    }
}

private enum DemoIndicatorColor: String, CaseIterable {
    case adaptive, white, accent

    var color: Color? {
        switch self {
        case .adaptive: nil
        case .white: .white
        case .accent: .accentColor
        }
    }
}

/// A pool of gradient cards used to demonstrate adding cards at runtime.
private struct ExtraCard {
    let title: String
    let symbol: String
    let background: RiffleCardBackground

    static let all: [ExtraCard] = [
        ExtraCard(title: "What's New", symbol: "wand.and.stars",
                  background: .gradient(light: [.blue, .cyan], dark: [.indigo, .blue])),
        ExtraCard(title: "Seasonal Offer", symbol: "gift.fill",
                  background: .gradient(light: [.green, .mint], dark: [.teal, .green])),
        ExtraCard(title: "Did You Know?", symbol: "lightbulb.fill",
                  background: .gradient(light: [.purple, .pink], dark: [.purple, .indigo])),
        ExtraCard(title: "Join the Beta", symbol: "hammer.fill",
                  background: .color(light: .teal, dark: Color(white: 0.18))),
    ]
}

#Preview {
    ContentView()
}
