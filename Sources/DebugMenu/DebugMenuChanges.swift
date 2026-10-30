import Combine

/// Tells open menus, and anything else watching, that the values rows show may have changed.
///
/// The menu sends it after every command it dispatches. When the app changes a value the menu shows from outside
/// the menu, call `DebugMenuChanges.shared.send()` so an open menu reads it again.
@MainActor
public final class DebugMenuChanges: ObservableObject {
    /// The signal open menus watch.
    public static let shared = DebugMenuChanges()

    /// Goes up by one on every `send()`. A remote can compare it to know when to fetch a new snapshot.
    @Published public private(set) var generation = 0

    /// Marks the menu's values as possibly changed.
    public func send() {
        generation += 1
    }
}
