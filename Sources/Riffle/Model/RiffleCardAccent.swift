import SwiftUI

/// A decorative image ("sticker") laid over a ``RiffleStandardCard``'s background, with
/// full control over where and how it sits: corner, fine offset, size, rotation, and
/// opacity. The image is drawn as-is — no border or shape is imposed.
///
/// ```swift
/// RiffleCard(id: "pro",
///            title: "Upgrade to Pro",
///            background: .gradient([.pink, .orange]),
///            accent: RiffleCardAccent(Image("badge"),
///                                     size: 80,
///                                     alignment: .topTrailing,
///                                     offset: CGSize(width: 8, height: -8),
///                                     rotation: .degrees(-12)))
/// ```
public struct RiffleCardAccent {
    let image: Image
    /// The largest dimension of the accent, in points (the image keeps its aspect ratio).
    var size: CGFloat
    /// Which corner/edge of the card the accent anchors to.
    var alignment: Alignment
    /// A fine positional nudge from the anchor. Positive `width` moves right, positive
    /// `height` moves down. The accent may extend past the card's edge.
    var offset: CGSize
    /// Rotation applied to the accent.
    var rotation: Angle
    /// Accent opacity, 0…1.
    var opacity: Double

    /// Creates an accent from an image.
    ///
    /// - Parameters:
    ///   - image: The image to lay over the card. Drawn as-is, scaled to fit `size`.
    ///   - size: The largest dimension in points. Defaults to 64.
    ///   - alignment: The corner/edge to anchor to. Defaults to the top trailing corner.
    ///   - offset: A positional nudge from the anchor. Defaults to none.
    ///   - rotation: Rotation of the accent. Defaults to none.
    ///   - opacity: Accent opacity. Defaults to fully opaque.
    public init(
        _ image: Image,
        size: CGFloat = 64,
        alignment: Alignment = .topTrailing,
        offset: CGSize = .zero,
        rotation: Angle = .zero,
        opacity: Double = 1
    ) {
        self.image = image
        self.size = size
        self.alignment = alignment
        self.offset = offset
        self.rotation = rotation
        self.opacity = opacity
    }
}
