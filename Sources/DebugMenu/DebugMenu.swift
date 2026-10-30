import os

private let logger = Logger(subsystem: "DebugMenu", category: "DebugMenu")

/// A built debug menu: a plain tree of sections, submenus and rows.
///
/// Every node gets a stable ID: the titles (or explicit `.id(_:)` values) on its path, joined with `/`.
/// For example a "Clear" button in a "Cache" submenu in a "Storage" section is `Storage/Cache/Clear`.
/// The same menu gives the same IDs on every launch and device.
///
/// If two nodes end up with the same ID, the later ones get `#2`, `#3` and so on, in declaration order,
/// and a notice is logged. Give one of them an explicit `.id(_:)` to choose a stable ID instead.
public struct DebugMenu: Sendable {
    let children: [DebugMenuNode]
    let itemsByID: [String: DebugItem]

    /// Builds a menu from its content.
    @MainActor
    public init(@DebugMenuBuilder _ content: () -> DebugMenuGroup) {
        var resolver = DebugMenuIDResolver()
        children = resolver.resolve(content().nodes, path: nil)
        itemsByID = resolver.itemsByID
    }
}

/// Turns each node's local key into a full, unique path ID.
private struct DebugMenuIDResolver {
    private static let pathSeparator = "/"
    private static let duplicateMarker = "#"

    private(set) var itemsByID: [String: DebugItem] = [:]
    private var usedIDs: Set<String> = []

    mutating func resolve(_ nodes: [DebugMenuNode], path: String?) -> [DebugMenuNode] {
        nodes.map { node in
            switch node {
            case .row(var item):
                item.id = uniqueID(for: item.id, path: path)
                itemsByID[item.id] = item
                return .row(item)
            case .container(var container):
                container.id = uniqueID(for: container.id, path: path)
                container.children = resolve(container.children, path: container.id)
                return .container(container)
            }
        }
    }

    private mutating func uniqueID(for key: String, path: String?) -> String {
        let baseID = path.map { $0 + Self.pathSeparator + key } ?? key
        var id = baseID
        var occurrence = 1
        while usedIDs.contains(id) {
            occurrence += 1
            id = baseID + Self.duplicateMarker + String(occurrence)
        }
        if id != baseID {
            logger.notice("Duplicate debug menu ID \(baseID, privacy: .public), using \(id, privacy: .public). Set .id(_:) to choose one.")
        }
        usedIDs.insert(id)
        return id
    }
}
