#if canImport(SwiftUI)
import SwiftUI
#endif

/// Storage for an app-supplied row. The view is kept apart from `DebugItem` so the rest of the model stays SwiftUI-free.
struct DebugCustomConfiguration: Sendable {
    /// Optional text the app supplies so the row has a value outside the UI, e.g. in a snapshot.
    let text: (@MainActor @Sendable () -> String?)?

    #if canImport(SwiftUI)
    let makeView: @MainActor @Sendable () -> AnyView
    #endif
}
