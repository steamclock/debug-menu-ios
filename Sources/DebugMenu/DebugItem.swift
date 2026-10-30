import Foundation

/// How a row is visually and behaviourally treated.
public enum DebugItemRole: String, Codable, Sendable {
    /// A regular row.
    case normal
    /// A row whose action destroys data or state, shown in a warning style.
    case destructive
}

/// A confirmation shown before a row's action runs.
public struct DebugConfirmation: Equatable, Codable, Sendable {
    /// The alert title.
    public let title: String
    /// Optional detail shown under the title.
    public let message: String?
    /// The label of the button that runs the action.
    public let confirmTitle: String
    /// The label of the button that dismisses the alert.
    public let cancelTitle: String

    /// Creates a confirmation.
    public init(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Continue",
        cancelTitle: String = "Cancel"
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
    }

    /// Shorthand for `DebugConfirmation(title:message:confirmTitle:cancelTitle:)`.
    public static func required(
        _ title: String,
        message: String? = nil,
        confirmTitle: String = "Continue",
        cancelTitle: String = "Cancel"
    ) -> DebugConfirmation {
        DebugConfirmation(title: title, message: message, confirmTitle: confirmTitle, cancelTitle: cancelTitle)
    }
}

/// A value a picker row can choose from all of its cases.
public protocol DebugPickerValue: CaseIterable, Hashable, Sendable {
    /// The option's label.
    var debugTitle: String { get }
    /// Optional detail shown under the label.
    var debugSubtitle: String? { get }
}

public extension DebugPickerValue {
    /// No subtitle by default.
    var debugSubtitle: String? { nil }
}

/// Visibility and disabled state for a row, read when the menu is shown.
struct DebugItemAvailability: Sendable {
    let isVisible: @MainActor @Sendable () -> Bool
    let isDisabled: @MainActor @Sendable () -> Bool
    let disabledReason: @MainActor @Sendable () -> String?

    static let enabled = DebugItemAvailability()

    init(
        visibleWhen isVisible: @escaping @MainActor @Sendable () -> Bool = { true },
        disabledWhen isDisabled: @escaping @MainActor @Sendable () -> Bool = { false },
        disabledReason: @escaping @MainActor @Sendable () -> String? = { nil }
    ) {
        self.isVisible = isVisible
        self.isDisabled = isDisabled
        self.disabledReason = disabledReason
    }
}

/// One selectable value in a picker row.
struct DebugPickerOption: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let isSelected: @MainActor @Sendable () -> Bool
    let select: @MainActor @Sendable () -> Void
}

/// Type-erased picker state. Options are rebuilt on each read so `isSelected` reflects the app's value.
struct DebugPickerConfiguration: Sendable {
    private let makeOptions: @MainActor @Sendable () -> [DebugPickerOption]

    @MainActor
    var options: [DebugPickerOption] {
        makeOptions()
    }

    @MainActor
    var selectedOption: DebugPickerOption? {
        options.first { $0.isSelected() }
    }

    /// Option IDs are `String(describing:)` of each value, so an enum case gives its case name.
    init<Value: Hashable & Sendable>(
        options values: [Value],
        title: @escaping @Sendable (Value) -> String,
        subtitle: @escaping @Sendable (Value) -> String? = { _ in nil },
        get: @escaping @MainActor @Sendable () -> Value,
        set: @escaping @MainActor @Sendable (Value) -> Void
    ) {
        self.makeOptions = {
            values.map { value in
                DebugPickerOption(
                    id: String(describing: value),
                    title: title(value),
                    subtitle: subtitle(value),
                    isSelected: { get() == value },
                    select: { set(value) }
                )
            }
        }
    }

    init<Value: DebugPickerValue>(
        get: @escaping @MainActor @Sendable () -> Value,
        set: @escaping @MainActor @Sendable (Value) -> Void
    ) {
        self.init(options: Array(Value.allCases), title: \.debugTitle, subtitle: \.debugSubtitle, get: get, set: set)
    }
}

/// The kind of interaction a row represents.
enum DebugItemKind: Sendable {
    /// A Bool toggle. `get` reads the app's value, `set` writes it.
    case toggle(get: @MainActor @Sendable () -> Bool, set: @MainActor @Sendable (Bool) -> Void)
    /// A button that runs an action.
    case action(@MainActor @Sendable () -> Void)
    /// A button that runs an async action, which can fail.
    case asyncAction(@MainActor @Sendable () async throws -> Void)
    /// A read-only, copyable value.
    case info(@MainActor @Sendable () -> String?)
    /// A single-value picker.
    case picker(DebugPickerConfiguration)
    /// An app-supplied row.
    case custom(DebugCustomConfiguration)
}

/// A built row. Its contents are internal; read rows through `DebugMenuSnapshot`.
public struct DebugItem: Sendable {
    /// Starts as the row's local key (its explicit ID or title). Building the menu prefixes it with the tree path.
    var id: String
    let title: String
    let kind: DebugItemKind
    var role: DebugItemRole = .normal
    var confirmation: DebugConfirmation?
    var helpText: String?
    var availability: DebugItemAvailability = .enabled
}
