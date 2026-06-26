import SwiftUI

/// A ready-made card for the common upsell, prompt, or tip layout, so you don't have
/// to build one by hand.
///
/// It renders a card with an optional leading symbol, a bold title, an optional
/// message, a trailing chevron when the card is tappable, and an optional dismiss
/// button. The background is a ``RiffleCardBackground``, so it can be a solid color, a
/// gradient, or any `ShapeStyle`, with separate light- and dark-mode variants.
///
/// The easiest way to use it is the matching ``RiffleCard`` initializer:
///
/// ```swift
/// RiffleStack {
///     RiffleCard(id: "pro",
///                title: "Upgrade to Pro",
///                message: "Unlock everything.",
///                systemImage: "sparkles",
///                background: .gradient(light: [.pink, .orange], dark: [.purple, .indigo]),
///                action: { showPaywall() })
///         .priority(.high)
///         .shown(when: !isPro)
/// }
/// ```
///
/// You can also use it directly as the content of a custom ``RiffleCard`` when you only
/// want the layout.
@MainActor
public struct RiffleStandardCard: View {
    private let title: String
    private let message: String?
    private let systemImage: String?
    private let background: RiffleCardBackground
    private let accent: RiffleCardAccent?
    private let accessory: RiffleCardAccessory
    private let onDismiss: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    /// Creates a standard card.
    ///
    /// - Parameters:
    ///   - title: The headline, shown in bold.
    ///   - message: An optional supporting line beneath the title.
    ///   - systemImage: An optional SF Symbol name shown as a leading badge.
    ///   - background: The card's background. Defaults to a solid accent color. Use a
    ///     ``RiffleCardBackground`` for gradients, images, or distinct light/dark variants.
    ///   - accent: An optional decorative image (a "sticker"). Use ``RiffleCardAccent``
    ///     to control its size, corner, offset, rotation, and opacity.
    ///   - accessory: The trailing glyph (``RiffleCardAccessory``): `.chevron`, `.none`,
    ///     or a custom `.symbol(_:)`. Defaults to none.
    ///   - onDismiss: When set, shows a close button that calls this closure.
    public init(
        title: String,
        message: String? = nil,
        systemImage: String? = nil,
        background: RiffleCardBackground = .color(.accentColor),
        accent: RiffleCardAccent? = nil,
        accessory: RiffleCardAccessory = .none,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.background = background
        self.accent = accent
        self.accessory = accessory
        self.onDismiss = onDismiss
    }

    public var body: some View {
        GeometryReader { geo in
            // Scale the chrome to the available height so the card stays legible from
            // tall hero cards down to short, dense ones.
            let h = geo.size.height
            let iconSize = min(44, max(20, h * 0.5))
            let titleSize = min(17, max(11, h * 0.2))
            let messageSize = min(15, max(10, h * 0.17))
            let spacing = min(14, max(8, h * 0.16))
            let hPad = min(18, max(12, h * 0.2))
            let corner = min(24, max(10, h * 0.3))
            // Drop the supporting line when there isn't room for two text lines.
            let showMessage = message != nil && h >= 56
            // Reserve room on the trailing edge for the dismiss button so it never
            // overlaps the accessory glyph or the title.
            let trailingPad = onDismiss != nil ? max(hPad, 38) : hPad

            HStack(spacing: spacing) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSize * 0.58))
                        .frame(width: iconSize, height: iconSize)
                        .background(.white.opacity(0.18), in: Circle())
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: titleSize, weight: .semibold))
                        .lineLimit(showMessage ? 1 : 2)
                        .minimumScaleFactor(0.6)
                    if showMessage, let message {
                        Text(message)
                            .font(.system(size: messageSize))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let symbol = accessory.symbol {
                    Image(systemName: symbol)
                        .font(.system(size: max(11, titleSize * 0.85), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .accessibilityHidden(true)
                }
            }
            .padding(.leading, hPad)
            .padding(.trailing, trailingPad)
            .frame(width: geo.size.width, height: h, alignment: .leading)
            .foregroundStyle(.white)
            .background { background.view(for: colorScheme) }
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        // The accent sits above the rounded clip so it can fill a corner or sit at an
        // angle without being cropped by the card's curve.
        .overlay(alignment: accent?.alignment ?? .center) {
            if let accent {
                accent.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: accent.size, height: accent.size)
                    .rotationEffect(accent.rotation)
                    .offset(accent.offset)
                    .opacity(accent.opacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .topTrailing) {
            if let onDismiss {
                // A real button, so it gets the system's tap target, press feedback, and
                // hit-test priority over the whole-card tap. The caller supplies only the
                // action; the card owns the button.
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.22), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(10)
                // The stack exposes dismiss as a VoiceOver action; hide the raw control
                // so it doesn't pollute the combined card label.
                .accessibilityHidden(true)
            }
        }
        }
    }
}
