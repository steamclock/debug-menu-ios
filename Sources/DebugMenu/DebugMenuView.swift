#if os(iOS)
import os
import SwiftUI

private let logger = Logger(subsystem: "DebugMenu", category: "DebugMenuView")

/// Shows a debug menu as a list. Put it in a `NavigationView` or `NavigationStack`, since submenus and pickers
/// push screens. `.debugMenuTrigger()` does that for you.
///
/// The menu is rebuilt from `content` each time the view updates, so `if` and `for` in the menu follow the app's
/// state. Rows change values through `DebugMenu.dispatch(_:)`, the same path a remote uses.
public struct DebugMenuView: View {
    private static let title = "Debug Menu"

    private let content: @MainActor () -> DebugMenuGroup
    @ObservedObject private var changes: DebugMenuChanges

    /// Creates a menu view from the same content `DebugMenu { }` takes.
    public init(@DebugMenuBuilder content: @escaping @MainActor () -> DebugMenuGroup) {
        self.content = content
        changes = .shared
    }

    public var body: some View {
        let menu = DebugMenu(content)
        DebugMenuScreen(title: Self.title, nodes: menu.children, menu: menu)
    }
}

/// Wraps the menu in navigation, with `NavigationStack` where it's available.
struct DebugMenuNavigation<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack { content }
        } else {
            NavigationView { content }
                .navigationViewStyle(.stack)
        }
    }
}

/// One screen of the menu: the top level, or a submenu.
struct DebugMenuScreen: View {
    let title: String
    let nodes: [DebugMenuNode]
    let menu: DebugMenu

    var body: some View {
        List {
            DebugNodeList(nodes: nodes, menu: menu)
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

    var body: some View {
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
                DebugMenuScreen(title: container.title, nodes: container.children, menu: menu)
            } label: {
                Text(container.title)
            }
        }
    }
}

extension DebugMenuNode: Identifiable {
    var id: String {
        switch self {
        case .row(let item): item.id
        case .container(let container): container.id
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
            logger.error("Debug menu command failed. row: \(command.rowID, privacy: .public), error: \(errorDescription, privacy: .public)")
        }
        return result
    }
}
#endif
