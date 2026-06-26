import SwiftUI

/// The background fill for a ``RiffleStandardCard``.
///
/// A background can be a solid color, a gradient, any SwiftUI `ShapeStyle`, or an image
/// (full-bleed), and can carry separate light- and dark-mode variants so a card adapts
/// to the color scheme.
///
/// ```swift
/// // Solid color, same in light and dark.
/// .color(.orange)
///
/// // Distinct light and dark colors.
/// .color(light: .orange, dark: .brown)
///
/// // A gradient with light and dark variants.
/// .gradient(light: [.pink, .orange], dark: [.purple, .indigo])
///
/// // A full-bleed image, cropped to fill the card.
/// .image(Image("hero"))
///
/// // Any other ShapeStyle, e.g. a material or radial gradient.
/// RiffleCardBackground(.ultraThinMaterial)
/// ```
public struct RiffleCardBackground: Sendable {
    private enum Fill {
        case style(light: AnyShapeStyle, dark: AnyShapeStyle)
        case image(light: Image, dark: Image, contentMode: ContentMode)
    }

    private let fill: Fill

    /// A background that uses `style` in both light and dark mode.
    public init<S: ShapeStyle>(_ style: S) {
        self.fill = .style(light: AnyShapeStyle(style), dark: AnyShapeStyle(style))
    }

    /// A background that uses `light` in light mode and `dark` in dark mode.
    public init<L: ShapeStyle, D: ShapeStyle>(light: L, dark: D) {
        self.fill = .style(light: AnyShapeStyle(light), dark: AnyShapeStyle(dark))
    }

    private init(fill: Fill) { self.fill = fill }

    /// The background, resolved for the given color scheme, sized to fill the card.
    @ViewBuilder
    func view(for scheme: ColorScheme) -> some View {
        switch fill {
        case let .style(light, dark):
            Rectangle().fill(scheme == .dark ? dark : light)
        case let .image(light, dark, contentMode):
            (scheme == .dark ? dark : light)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }
}

public extension RiffleCardBackground {
    /// A solid color, the same in light and dark mode.
    static func color(_ color: Color) -> RiffleCardBackground {
        RiffleCardBackground(color)
    }

    /// A solid color that differs between light and dark mode.
    static func color(light: Color, dark: Color) -> RiffleCardBackground {
        RiffleCardBackground(light: light, dark: dark)
    }

    /// A linear gradient, the same in light and dark mode.
    static func gradient(
        _ colors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> RiffleCardBackground {
        RiffleCardBackground(LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint))
    }

    /// A linear gradient that differs between light and dark mode.
    static func gradient(
        light: [Color],
        dark: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> RiffleCardBackground {
        RiffleCardBackground(
            light: LinearGradient(colors: light, startPoint: startPoint, endPoint: endPoint),
            dark: LinearGradient(colors: dark, startPoint: startPoint, endPoint: endPoint)
        )
    }

    /// A full-bleed image, cropped to fill the card (`.fill`) or fit within it (`.fit`).
    static func image(_ image: Image, contentMode: ContentMode = .fill) -> RiffleCardBackground {
        RiffleCardBackground(fill: .image(light: image, dark: image, contentMode: contentMode))
    }

    /// A full-bleed image that differs between light and dark mode.
    static func image(light: Image, dark: Image, contentMode: ContentMode = .fill) -> RiffleCardBackground {
        RiffleCardBackground(fill: .image(light: light, dark: dark, contentMode: contentMode))
    }
}
