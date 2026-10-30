#if os(iOS)
import os
import SwiftUI

private let logger = Logger(subsystem: "DebugMenu", category: "DebugMenuView")

/// Shows a debug menu as a list. Put it in a `NavigationStack`, since submenus and pickers push screens.
/// `.debugMenuTrigger()` does that for you.
///
/// The menu is rebuilt from `content` each time the view updates, so `if` and `for` in the menu follow the app's
/// state. Rows change values through `DebugMenu.dispatch(_:)`, the same path a remote uses.
public struct DebugMenuView: View {
    static let title = "Debug Menu"

    private let content: @MainActor () -> DebugMenuGroup

    /// Creates a menu view from the same content `DebugMenu { }` takes.
    public init(@DebugMenuBuilder content: @escaping @MainActor () -> DebugMenuGroup) {
        self.content = content
    }

    /// The menu's top-level screen, with `DebugMenuChanges.shared` in the environment for its rows.
    public var body: some View {
        DebugMenuRoot(content: content)
            .environment(DebugMenuChanges.shared)
    }
}

/// Builds the menu and shows its top-level screen.
private struct DebugMenuRoot: View {
    let content: @MainActor () -> DebugMenuGroup

    @Environment(DebugMenuChanges.self) private var changes

    var body: some View {
        // Rebuild on every change, so `if` and `for` over storage SwiftUI can't observe follow it too.
        let _ = changes.generation
        let menu = DebugMenu(content)
        DebugMenuScreen(title: DebugMenuView.title, nodes: menu.children, menu: menu)
    }
}

/// One screen of the menu: the top level, or a submenu.
struct DebugMenuScreen: View {
    let title: String
    let nodes: [DebugMenuNode]
    let menu: DebugMenu

    var body: some View {
        List {
            ForEach(nodes.listSections) { section in
                Section(header: section.title.map(Text.init)) {
                    DebugNodeList(nodes: section.nodes, menu: menu)
                }
            }
        }
        .navigationTitle(title)
    }
}

private struct DebugNodeList: View {
    let nodes: [DebugMenuNode]
    let menu: DebugMenu

    var body: some View {
        ForEach(nodes) { node in
            DebugNodeView(node: node, menu: menu)
        }
    }
}

private struct DebugNodeView: View {
    let node: DebugMenuNode
    let menu: DebugMenu

    @Environment(DebugMenuChanges.self) private var changes

    var body: some View {
        // Re-reads `isVisible` on every change. See `DebugItemRow`.
        let _ = changes.generation
        switch node {
        case .row(let item):
            if item.availability.isVisible() {
                DebugItemRow(item: item, menu: menu)
            }
        case .container(let container) where container.style == .section:
            Section(header: Text(container.title)) {
                DebugNodeList(nodes: container.children, menu: menu)
            }
        case .container(let container):
            NavigationLink {
                // A pushed screen doesn't inherit environment values set inside the `NavigationStack`, so pass it on.
                DebugMenuScreen(title: container.title, nodes: container.children, menu: menu)
                    .environment(changes)
            } label: {
                Text(container.title)
            }
        }
    }
}

extension DebugMenu {
    /// Dispatches a command from the UI and logs a failure, since most rows have nowhere to show one.
    @discardableResult
    func perform(_ command: DebugCommand) async -> DebugCommandResult {
        let result = await dispatch(command)
        if case .failure(let error) = result {
            let errorDescription = String(describing: error)
            logger.error(
                "Debug menu command failed. row: \(command.rowID, privacy: .public), error: \(errorDescription, privacy: .private)"
            )
        }
        return result
    }

    /// Starts `command` without waiting for its result.
    func start(_ command: DebugCommand) {
        Task { await perform(command) }
    }
}
#endif
