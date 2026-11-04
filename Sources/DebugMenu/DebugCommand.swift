import Foundation

/// Something to do to a row, addressed by its ID from `DebugMenuSnapshot`. The menu UI and a remote both use these.
@available(iOS 17, *)
public enum DebugCommand: Codable, Sendable, Equatable {
    /// Sets a toggle row's value.
    case setToggle(rowID: String, isOn: Bool)
    /// Selects a picker row's option by its ID.
    case selectOption(rowID: String, optionID: String)
    /// Runs a button's action.
    case runAction(rowID: String)
    /// Runs a button's async action and waits for it to finish.
    case runAsyncAction(rowID: String)
    /// Points an environment picker at a typed-in server. The picker must accept custom URLs.
    case setCustomURL(rowID: String, url: URL)

    /// The row the command addresses.
    public var rowID: String {
        switch self {
        case .setToggle(let rowID, _), .selectOption(let rowID, _), .runAction(let rowID), .runAsyncAction(let rowID),
             .setCustomURL(let rowID, _):
            rowID
        }
    }
}

/// Why a command failed.
@available(iOS 17, *)
public enum DebugCommandError: Error, Codable, Sendable, Equatable {
    /// No row has this ID.
    case unknownRow(rowID: String)
    /// The row isn't the kind the command needs. `kind` is the row's actual kind.
    case wrongKind(rowID: String, kind: DebugMenuSnapshot.Kind)
    /// The picker has no option with this ID.
    case unknownOption(rowID: String, optionID: String)
    /// The row is hidden or disabled.
    case unavailable(rowID: String)
    /// The picker doesn't accept custom URLs.
    case customURLUnsupported(rowID: String)
    /// The URL isn't an `http` or `https` URL with a host.
    case invalidURL(rowID: String, url: URL)
    /// The async action threw. `message` describes the error.
    case actionFailed(rowID: String, message: String)
}

/// The outcome of a command.
@available(iOS 17, *)
public enum DebugCommandResult: Codable, Sendable, Equatable {
    /// The command was applied.
    case success
    /// The command wasn't applied, or its async action threw.
    case failure(DebugCommandError)
}

@available(iOS 17, *)
public extension DebugMenu {
    /// Applies a command to the row it addresses. Async actions are awaited, and their errors returned.
    ///
    /// Confirmations are not shown here. The caller asks first, using the row's `confirmation`.
    /// Afterwards the menu's `DebugMenuChanges` is sent, since the command may have changed what rows show.
    @MainActor
    func dispatch(_ command: DebugCommand) async -> DebugCommandResult {
        defer { changes.send() }
        do {
            try await apply(command)
            return .success
        } catch {
            return .failure(error)
        }
    }
}

@available(iOS 17, *)
private extension DebugMenu {
    @MainActor
    func apply(_ command: DebugCommand) async throws(DebugCommandError) {
        let rowID = command.rowID
        guard let item = itemsByID[rowID] else {
            throw .unknownRow(rowID: rowID)
        }
        guard item.availability.isVisible(), !item.availability.isDisabled() else {
            throw .unavailable(rowID: rowID)
        }
        switch (command, item.kind) {
        case (.setToggle(_, let isOn), .toggle(_, let set)):
            set(isOn)
        case (.selectOption(_, let optionID), .picker(let picker)):
            guard let option = picker.options.first(where: { $0.id == optionID }) else {
                throw .unknownOption(rowID: rowID, optionID: optionID)
            }
            option.select()
        case (.setCustomURL(_, let url), .picker(let picker)):
            try picker.applyCustomURL(url, rowID: rowID)
        case (.runAction, .action(let action)):
            action()
        case (.runAsyncAction, .asyncAction(let action)):
            do {
                try await action()
            } catch {
                throw .actionFailed(rowID: rowID, message: String(describing: error))
            }
        default:
            throw .wrongKind(rowID: rowID, kind: item.kind.snapshotContent.kind)
        }
    }
}

@available(iOS 17, *)
private extension DebugPickerConfiguration {
    @MainActor
    func applyCustomURL(_ url: URL, rowID: String) throws(DebugCommandError) {
        guard let setCustomURL else {
            throw .customURLUnsupported(rowID: rowID)
        }
        guard url.isServerURL else {
            throw .invalidURL(rowID: rowID, url: url)
        }
        setCustomURL(url)
    }
}
