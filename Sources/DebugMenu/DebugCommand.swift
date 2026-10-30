/// Something to do to a row, addressed by its ID from `DebugMenuSnapshot`. The menu UI and a remote both use these.
public enum DebugCommand: Codable, Sendable, Equatable {
    /// Sets a toggle row's value.
    case setToggle(rowID: String, isOn: Bool)
    /// Selects a picker row's option by its ID.
    case selectOption(rowID: String, optionID: String)
    /// Runs a button's action.
    case runAction(rowID: String)
    /// Runs a button's async action and waits for it to finish.
    case runAsyncAction(rowID: String)

    /// The row the command addresses.
    public var rowID: String {
        switch self {
        case .setToggle(let rowID, _), .selectOption(let rowID, _), .runAction(let rowID), .runAsyncAction(let rowID):
            rowID
        }
    }
}

/// Why a command failed.
public enum DebugCommandError: Error, Codable, Sendable, Equatable {
    /// No row has this ID.
    case unknownRow(rowID: String)
    /// The row isn't the kind the command needs. `kind` is the row's actual kind.
    case wrongKind(rowID: String, kind: DebugMenuSnapshot.Kind)
    /// The picker has no option with this ID.
    case unknownOption(rowID: String, optionID: String)
    /// The row is hidden or disabled.
    case unavailable(rowID: String)
    /// The async action threw. `message` describes the error.
    case actionFailed(rowID: String, message: String)
}

/// The outcome of a command.
public enum DebugCommandResult: Codable, Sendable, Equatable {
    /// The command was applied.
    case success
    /// The command wasn't applied, or its async action threw.
    case failure(DebugCommandError)
}

public extension DebugMenu {
    /// Applies a command to the row it addresses. Async actions are awaited, and their errors returned.
    ///
    /// Confirmations are not shown here. The caller asks first, using the row's `confirmation`.
    /// Afterwards `DebugMenuChanges.shared` is sent, since the command may have changed what rows show.
    @MainActor
    func dispatch(_ command: DebugCommand) async -> DebugCommandResult {
        defer { DebugMenuChanges.shared.send() }
        do {
            try await apply(command)
            return .success
        } catch {
            return .failure(error)
        }
    }
}

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
        case (.runAction, .action(let action)):
            action()
        case (.runAsyncAction, .asyncAction(let action)):
            do {
                try await action()
            } catch {
                throw .actionFailed(rowID: rowID, message: String(describing: error))
            }
        default:
            throw .wrongKind(rowID: rowID, kind: item.kind.snapshotKind)
        }
    }
}
