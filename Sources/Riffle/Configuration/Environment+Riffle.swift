import SwiftUI

private struct RiffleConfigurationKey: EnvironmentKey {
    // A computed default avoids a global stored value of a non-Sendable type
    // while still handing every subtree a fresh configuration.
    static var defaultValue: RiffleConfiguration { RiffleConfiguration() }
}

extension EnvironmentValues {
    /// The resolved Riffle configuration for the current view subtree.
    var riffleConfiguration: RiffleConfiguration {
        get { self[RiffleConfigurationKey.self] }
        set { self[RiffleConfigurationKey.self] = newValue }
    }
}
