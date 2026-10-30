/// A `Codable` description of the whole menu at one moment. Values are read through each row's `get` when it's taken.
///
/// Everything the menu UI can see is here, keyed by stable node IDs, so a remote can show the menu and drive it
/// with `DebugCommand`s.
public struct DebugMenuSnapshot: Codable, Sendable, Equatable {
    /// The kind of a node.
    public enum Kind: String, Codable, Sendable {
        /// A titled group of rows.
        case section
        /// A row that opens a nested menu.
        case submenu
        /// An on/off row. Its value is in `isOn`.
        case toggle
        /// A button. Run it with `DebugCommand.runAction`.
        case action
        /// A button with an async action. Run it with `DebugCommand.runAsyncAction`.
        case asyncAction
        /// A read-only value. Its value is in `text`.
        case info
        /// A single-choice row. Its value is in `selectedOptionID`, its choices in `options`.
        case picker
        /// An app-supplied view, which can't be shown outside the app. `text` holds the app's optional stand-in.
        case custom
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
        /// What kind of node this is.
        public let kind: Kind
        /// The node's title.
        public let title: String
        /// Child nodes of a section or submenu, `nil` for rows.
        public let children: [Node]?
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
        /// A toggle's current value.
        public let isOn: Bool?
        /// A picker's currently selected option, or `nil` if the app's value isn't one of the options.
        public let selectedOptionID: String?
        /// A picker's options.
        public let options: [Option]?
        /// An info row's value, or a custom row's stand-in text.
        public let text: String?
    }

    /// The top-level nodes in declaration order.
    public let nodes: [Node]
}

public extension DebugMenu {
    /// Describes the whole menu as it is right now.
    @MainActor
    func snapshot() -> DebugMenuSnapshot {
        DebugMenuSnapshot(nodes: children.map(DebugMenuSnapshot.Node.init))
    }
}

extension DebugItemKind {
    var snapshotKind: DebugMenuSnapshot.Kind {
        switch self {
        case .toggle: .toggle
        case .action: .action
        case .asyncAction: .asyncAction
        case .info: .info
        case .picker: .picker
        case .custom: .custom
        }
    }
}

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
            kind: container.style == .section ? .section : .submenu,
            title: container.title,
            children: container.children.map(Self.init),
            role: .normal,
            helpText: nil,
            isVisible: true,
            isDisabled: false,
            disabledReason: nil,
            confirmation: nil,
            isOn: nil,
            selectedOptionID: nil,
            options: nil,
            text: nil
        )
    }

    @MainActor
    init(_ item: DebugItem) {
        var isOn: Bool?
        var selectedOptionID: String?
        var options: [DebugMenuSnapshot.Option]?
        var text: String?
        switch item.kind {
        case .toggle(let get, _):
            isOn = get()
        case .picker(let picker):
            let pickerOptions = picker.options
            selectedOptionID = pickerOptions.first { $0.isSelected() }?.id
            options = pickerOptions.map { DebugMenuSnapshot.Option(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
        case .info(let value):
            text = value()
        case .custom(let custom):
            text = custom.text()
        case .action, .asyncAction:
            break
        }
        self.init(
            id: item.id,
            kind: item.kind.snapshotKind,
            title: item.title,
            children: nil,
            role: item.role,
            helpText: item.helpText,
            isVisible: item.availability.isVisible(),
            isDisabled: item.availability.isDisabled(),
            disabledReason: item.availability.disabledReason(),
            confirmation: item.confirmation,
            isOn: isOn,
            selectedOptionID: selectedOptionID,
            options: options,
            text: text
        )
    }
}
