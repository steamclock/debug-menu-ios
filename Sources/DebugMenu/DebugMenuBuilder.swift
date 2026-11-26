/// Content that goes inside a `DebugMenu`: a row, a section, a submenu, or your own type that groups them.
///
/// Conform your own type to move part of a menu out of line:
///
/// ```swift
/// struct CacheMenu: DebugMenuContent {
///     let cache: Cache
///     var body: DebugMenuGroup {
///         DebugInfo("Size", value: cache.formattedSize)
///         DebugButton("Clear", role: .destructive) { cache.clear() }
///     }
/// }
/// ```
@MainActor
public protocol DebugMenuContent {
    /// The rows, sections and submenus this content adds to the menu.
    @DebugMenuBuilder var body: DebugMenuGroup { get }
}

/// Built menu content, produced by `DebugMenuBuilder`. It has no public members.
public struct DebugMenuGroup: DebugMenuContent, Sendable {
    let nodes: [DebugMenuNode]

    /// Returns itself.
    public var body: DebugMenuGroup {
        return self
    }
}

/// Builds menu content from rows, sections, submenus, `if`, `if #available` and `for` loops.
@MainActor
@resultBuilder
public enum DebugMenuBuilder {
    /// Resolves a piece of content to its nodes.
    public static func buildExpression(_ content: some DebugMenuContent) -> DebugMenuGroup {
        content.body
    }

    /// Joins the statements of a block in order.
    public static func buildBlock(_ groups: DebugMenuGroup...) -> DebugMenuGroup {
        DebugMenuGroup(nodes: groups.flatMap(\.nodes))
    }

    /// Supports `if` without `else`.
    public static func buildOptional(_ group: DebugMenuGroup?) -> DebugMenuGroup {
        group ?? DebugMenuGroup(nodes: [])
    }

    /// Supports the `if` branch of `if/else` and `switch`.
    public static func buildEither(first group: DebugMenuGroup) -> DebugMenuGroup {
        group
    }

    /// Supports the `else` branch of `if/else` and `switch`.
    public static func buildEither(second group: DebugMenuGroup) -> DebugMenuGroup {
        group
    }

    /// Supports `for` loops.
    public static func buildArray(_ groups: [DebugMenuGroup]) -> DebugMenuGroup {
        DebugMenuGroup(nodes: groups.flatMap(\.nodes))
    }

    /// Supports `if #available`.
    public static func buildLimitedAvailability(_ group: DebugMenuGroup) -> DebugMenuGroup {
        group
    }
}

/// A node in the built menu tree.
enum DebugMenuNode: Sendable {
    case row(DebugItem)
    case container(DebugContainer)
}

extension DebugMenuNode: Identifiable {
    var id: String {
        switch self {
        case .row(let item): item.id
        case .container(let container): container.id
        }
    }
}

/// One section of a menu screen's list: a `DebugSection`, or an untitled run of the nodes between sections.
struct DebugListSection: Identifiable {
    let id: String
    let title: String?
    let nodes: [DebugMenuNode]
}

extension [DebugMenuNode] {
    /// These nodes as list sections, so a screen's list holds only sections.
    ///
    /// A SwiftUI `List` that mixes loose rows and sections at the top level shows sections that start offscreen
    /// as blank rows (seen on iOS 18.5), so each run of loose nodes goes in an untitled section.
    var listSections: [DebugListSection] {
        var sections: [DebugListSection] = []
        var looseNodes: [DebugMenuNode] = []
        for node in self {
            guard case .container(let container) = node, container.style == .section else {
                looseNodes.append(node)
                continue
            }
            sections.appendUntitled(&looseNodes)
            sections.append(DebugListSection(id: container.id, title: container.title, nodes: container.children))
        }
        sections.appendUntitled(&looseNodes)
        return sections
    }
}

private extension [DebugListSection] {
    mutating func appendUntitled(_ nodes: inout [DebugMenuNode]) {
        guard let first = nodes.first else {
            return
        }
        append(DebugListSection(id: first.id, title: nil, nodes: nodes))
        nodes = []
    }
}

/// A section or submenu and its children.
struct DebugContainer: Sendable {
    enum Style: String, Sendable {
        case section
        case submenu
    }

    /// Starts as the local key (explicit ID or title). Building the menu prefixes it with the tree path.
    var id: String
    let title: String
    let style: Style
    var children: [DebugMenuNode]
}

/// A titled group of rows, like a `Section` in a SwiftUI `List`.
public struct DebugSection: DebugMenuContent, Sendable {
    private var container: DebugContainer

    /// Creates a section. Its title becomes part of the IDs of everything inside it.
    public init(_ title: String, @DebugMenuBuilder content: () -> DebugMenuGroup) {
        container = DebugContainer(id: title, title: title, style: .section, children: content().nodes)
    }

    /// The section as a menu node.
    public var body: DebugMenuGroup {
        return DebugMenuGroup(nodes: [.container(container)])
    }

    /// Replaces the title in this section's ID, and so in the IDs of everything inside it.
    public func id(_ id: String) -> DebugSection {
        var copy = self
        copy.container.id = id
        return copy
    }
}

/// A row that opens a nested menu. Declare its content inline, or with a type that conforms to `DebugMenuContent`.
public struct DebugSubmenu: DebugMenuContent, Sendable {
    private var container: DebugContainer

    /// Creates a submenu. Its title becomes part of the IDs of everything inside it.
    public init(_ title: String, @DebugMenuBuilder content: () -> DebugMenuGroup) {
        container = DebugContainer(id: title, title: title, style: .submenu, children: content().nodes)
    }

    /// The submenu as a menu node.
    public var body: DebugMenuGroup {
        return DebugMenuGroup(nodes: [.container(container)])
    }

    /// Replaces the title in this submenu's ID, and so in the IDs of everything inside it.
    public func id(_ id: String) -> DebugSubmenu {
        var copy = self
        copy.container.id = id
        return copy
    }
}
