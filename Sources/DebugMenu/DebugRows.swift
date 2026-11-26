/// A single menu row. The built-in rows conform, so the modifiers below work on all of them.
public protocol DebugRow: DebugMenuContent {
    /// The row's built definition.
    var item: DebugItem { get set }
}

public extension DebugRow {
    /// The row as a menu node.
    var body: DebugMenuGroup {
        return DebugMenuGroup(nodes: [.row(item)])
    }

    /// Replaces the title in this row's ID. Use it when the title changes at runtime, so the ID doesn't.
    func id(_ id: String) -> Self {
        var copy = self
        copy.item.id = id
        return copy
    }

    /// Adds help text shown under the row.
    func help(_ text: String) -> Self {
        var copy = self
        copy.item.helpText = text
        return copy
    }

    /// Hides the row while `isHidden` is true. Read each time the menu is shown.
    func hidden(_ isHidden: @autoclosure @escaping @MainActor @Sendable () -> Bool) -> Self {
        var copy = self
        let availability = item.availability
        copy.item.availability = DebugItemAvailability(
            visibleWhen: { !isHidden() },
            disabledWhen: availability.isDisabled,
            disabledReason: availability.disabledReason
        )
        return copy
    }

    /// Disables the row while `isDisabled` is true, optionally saying why. Read each time the menu is shown.
    func disabled(
        _ isDisabled: @autoclosure @escaping @MainActor @Sendable () -> Bool,
        reason: @autoclosure @escaping @MainActor @Sendable () -> String? = nil
    ) -> Self {
        var copy = self
        copy.item.availability = DebugItemAvailability(
            visibleWhen: item.availability.isVisible,
            disabledWhen: isDisabled,
            disabledReason: reason
        )
        return copy
    }

    /// Asks the user to confirm before the row changes a value or runs its action.
    func confirmation(_ confirmation: DebugConfirmation) -> Self {
        var copy = self
        copy.item.confirmation = confirmation
        return copy
    }
}

/// An on/off row that reads and writes a Bool the app owns.
public struct DebugToggle: DebugRow {
    /// The row's built definition.
    public var item: DebugItem

    /// Creates a toggle that reads the app's value with `get` and writes it with `set`.
    public init(
        _ title: String,
        get: @escaping @MainActor @Sendable () -> Bool,
        set: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        item = DebugItem(id: title, title: title, kind: .toggle(get: get, set: set))
    }
}

/// A row that runs an action when tapped.
public struct DebugButton: DebugRow {
    /// The row's built definition.
    public var item: DebugItem

    /// Creates a button that runs `action`. Pass a `confirmation` to ask before running it.
    public init(
        _ title: String,
        role: DebugItemRole = .normal,
        confirmation: DebugConfirmation? = nil,
        action: @escaping @MainActor @Sendable () -> Void
    ) {
        item = DebugItem(id: title, title: title, kind: .action(action), role: role, confirmation: confirmation)
    }

    /// Creates a button that runs an async `action`. A thrown error is reported to whoever ran it.
    public init(
        _ title: String,
        role: DebugItemRole = .normal,
        confirmation: DebugConfirmation? = nil,
        action: @escaping @MainActor @Sendable () async throws -> Void
    ) {
        item = DebugItem(id: title, title: title, kind: .asyncAction(action), role: role, confirmation: confirmation)
    }
}

/// A row that picks one value from a list of options.
public struct DebugPicker: DebugRow {
    /// The row's built definition.
    public var item: DebugItem

    /// Creates a picker over every case of a `DebugPickerValue`.
    public init<Value: DebugPickerValue>(
        _ title: String,
        get: @escaping @MainActor @Sendable () -> Value,
        set: @escaping @MainActor @Sendable (Value) -> Void
    ) {
        item = DebugItem(id: title, title: title, kind: .picker(DebugPickerConfiguration(get: get, set: set)))
    }

    /// Creates a picker over an explicit list of options, labelled by `optionTitle`.
    /// Each option's ID is `String(describing:)` of its value.
    public init<Value: Hashable & Sendable>(
        _ title: String,
        options: [Value],
        optionTitle: @escaping @Sendable (Value) -> String,
        get: @escaping @MainActor @Sendable () -> Value,
        set: @escaping @MainActor @Sendable (Value) -> Void
    ) {
        let configuration = DebugPickerConfiguration(options: options, title: optionTitle, get: get, set: set)
        self.init(title, configuration: configuration)
    }

    init(_ title: String, configuration: DebugPickerConfiguration) {
        item = DebugItem(id: title, title: title, kind: .picker(configuration))
    }
}

/// A read-only row showing a value, which can be copied.
public struct DebugInfo: DebugRow {
    /// The row's built definition.
    public var item: DebugItem

    /// Creates an info row. `value` is read each time the menu is shown, not once.
    public init(_ title: String, value: @autoclosure @escaping @MainActor @Sendable () -> String?) {
        item = DebugItem(id: title, title: title, kind: .info(value))
    }
}
