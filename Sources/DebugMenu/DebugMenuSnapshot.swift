/// A `Codable` description of the whole menu at one moment. Values are read through each row's `get` when it's taken.
///
/// Everything the menu UI can see is here, keyed by stable node IDs, so a remote can show the menu and drive it
/// with `DebugCommand`s.
@available(iOS 17, *)
public struct DebugMenuSnapshot: Codable, Sendable, Equatable {
    /// The kind of a node, without its state. `DebugCommandError.wrongKind` reports it.
    public enum Kind: String, Codable, Sendable {
        /// A titled group of rows.
        case section
        /// A row that opens a nested menu.
        case submenu
        /// An on/off row.
        case toggle
        /// A button.
        case action
        /// A button with an async action.
        case asyncAction
        /// A read-only value.
        case info
        /// A single-choice row.
        case picker
        /// An app-supplied view.
        case custom
    }

    /// What a node is, with the state that only its kind has.
    public enum Content: Codable, Sendable, Equatable {
        /// A titled group of rows.
        case section(children: [Node])
        /// A row that opens a nested menu.
        case submenu(children: [Node])
        /// An on/off row and its current value.
        case toggle(isOn: Bool)
        /// A button. Run it with `DebugCommand.runAction`.
        case action
        /// A button with an async action. Run it with `DebugCommand.runAsyncAction`.
        case asyncAction
        /// A read-only value.
        case info(text: String?)
        /// A single-choice row. `selectedOptionID` is `nil` if the app's value isn't one of the options.
        /// When `acceptsCustomURL` is true, `DebugCommand.setCustomURL` sets it to a typed-in server.
        case picker(selectedOptionID: String?, options: [Option], acceptsCustomURL: Bool)
        /// An app-supplied view, which can't be shown outside the app. `text` is the app's optional stand-in.
        case custom(text: String?)

        /// The content's kind, without its state.
        public var kind: Kind {
            switch self {
            case .section: .section
            case .submenu: .submenu
            case .toggle: .toggle
            case .action: .action
            case .asyncAction: .asyncAction
            case .info: .info
            case .picker: .picker
            case .custom: .custom
            }
        }
    }

    /// One choice in a picker row.
    public struct Option: Codable, Sendable, Equatable {
        /// The ID to send in `DebugCommand.selectOption`.
        public let id: String
        /// The option's label.
        public let title: String
        /// Optional detail shown under the label.
        public let subtitle: String?
    }

    /// A section, submenu or row.
    public struct Node: Codable, Sendable, Equatable {
        /// The stable ID commands use to address this node.
        public let id: String
        /// What kind of node this is, and its kind's state, like a toggle's value.
        public let content: Content
        /// The node's title.
        public let title: String
        /// How the row is treated visually.
        public let role: DebugItemRole
        /// Help text shown under the row.
        public let helpText: String?
        /// Whether the row is shown. Hidden rows are still listed.
        public let isVisible: Bool
        /// Whether the row is disabled. Commands to a hidden or disabled row fail.
        public let isDisabled: Bool
        /// Why the row is disabled, if the app said.
        public let disabledReason: String?
        /// The confirmation the UI shows before running the row's action.
        public let confirmation: DebugConfirmation?

        /// What kind of node this is. The same as `content.kind`.
        public var kind: Kind {
            content.kind
        }

        /// Child nodes of a section or submenu. Empty for rows.
        public var children: [Node] {
            switch content {
            case .section(let children), .submenu(let children): children
            case .toggle, .action, .asyncAction, .info, .picker, .custom: []
            }
        }
    }

    /// The top-level nodes in declaration order.
    public let nodes: [Node]
}

@available(iOS 17, *)
public extension DebugMenu {
    /// Describes the whole menu as it is right now.
    @MainActor
    func snapshot() -> DebugMenuSnapshot {
        DebugMenuSnapshot(nodes: children.map(DebugMenuSnapshot.Node.init))
    }
}

@available(iOS 17, *)
extension DebugItemKind {
    /// The row's kind and current state, read through its closures.
    @MainActor
    var snapshotContent: DebugMenuSnapshot.Content {
        switch self {
        case .toggle(let get, _):
            .toggle(isOn: get())
        case .action:
            .action
        case .asyncAction:
            .asyncAction
        case .info(let value):
            .info(text: value())
        case .picker(let picker):
            .picker(
                selectedOptionID: picker.selectedOption?.id,
                options: picker.options.map { DebugMenuSnapshot.Option(id: $0.id, title: $0.title, subtitle: $0.subtitle) },
                acceptsCustomURL: picker.setCustomURL != nil
            )
        case .custom(let custom):
            .custom(text: custom.text())
        }
    }
}

@available(iOS 17, *)
private extension DebugMenuSnapshot.Node {
    @MainActor
    init(_ node: DebugMenuNode) {
        switch node {
        case .row(let item): self.init(item)
        case .container(let container): self.init(container)
        }
    }

    @MainActor
    init(_ container: DebugContainer) {
        self.init(
            id: container.id,
            content: container.style == .section
                ? .section(children: container.children.map(Self.init))
                : .submenu(children: container.children.map(Self.init)),
            title: container.title,
            role: .normal,
            helpText: nil,
            isVisible: true,
            isDisabled: false,
            disabledReason: nil,
            confirmation: nil
        )
    }

    @MainActor
    init(_ item: DebugItem) {
        self.init(
            id: item.id,
            content: item.kind.snapshotContent,
            title: item.title,
            role: item.role,
            helpText: item.helpText,
            isVisible: item.availability.isVisible(),
            isDisabled: item.availability.isDisabled(),
            disabledReason: item.availability.disabledReason(),
            confirmation: item.confirmation
        )
    }
}
