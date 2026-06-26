import SwiftUI

/// The animation used when the front card of a ``RiffleStack`` changes.
///
/// `.flip` is the default and produces the signature widget-style vertical flip.
/// When Reduce Motion is enabled every transition degrades to a cross-fade.
public enum RiffleTransition {
    /// A vertical 3D flip. The default.
    case flip

    /// The outgoing card slides off while the incoming card slides in.
    case slide

    /// The incoming card pushes the outgoing card out of the way.
    case push

    /// A simple cross-fade.
    case fade

    /// The incoming card scales up while fading in.
    case scale

    /// A caller-supplied transition.
    case custom(AnyTransition)
}
