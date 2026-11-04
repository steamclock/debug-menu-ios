import Observation

/// Tells open menus, and anything else watching, that the values rows show may have changed.
///
/// The menu sends it after every command it dispatches. Rows over an `@Observable` model refresh on their own, but
/// SwiftUI can't see changes to other storage, like `UserDefaults`. When the app changes a value like that from
/// outside the menu, call `DebugMenuChanges.shared.send()` so an open menu reads it again.
///
/// Menus use `shared` unless you give them another instance.
@available(iOS 17, *)
@MainActor
@Observable
public final class DebugMenuChanges {
    /// The signal open menus watch.
    public static let shared = DebugMenuChanges()

    /// Goes up by one on every `send()`. A remote can compare it to know when to fetch a new snapshot.
    public private(set) var generation = 0

    /// Creates a separate signal. Most apps use `shared` instead.
    public init() {}

    /// Marks the menu's values as possibly changed.
    public func send() {
        generation += 1
    }
}
