import Foundation

private enum DefaultTitle {
    static let environment = "Environment"
    static let advancedLogging = "Advanced logging"
    static let sendLogs = "Send logs"
}

public extension DebugPicker {
    /// An "Environment" picker. `set` is where the app switches, e.g. by signing out and pointing at a new server.
    /// Each option is labelled by `optionTitle`, which defaults to `String(describing:)` of the value.
    static func environment<Value: Hashable & Sendable>(
        options: [Value],
        optionTitle: @escaping @Sendable (Value) -> String = { String(describing: $0) },
        get: @escaping @MainActor @Sendable () -> Value,
        set: @escaping @MainActor @Sendable (Value) -> Void
    ) -> DebugPicker {
        DebugPicker(DefaultTitle.environment, options: options, optionTitle: optionTitle, get: get, set: set)
    }
}

public extension DebugToggle {
    /// An "Advanced logging" toggle over the app's own logging setting.
    static func advancedLogging(
        get: @escaping @MainActor @Sendable () -> Bool,
        set: @escaping @MainActor @Sendable (Bool) -> Void
    ) -> DebugToggle {
        DebugToggle(DefaultTitle.advancedLogging, get: get, set: set)
    }
}

/// One log for `DebugButton.sendLogs(logs:destination:)`.
public enum DebugLogFile: Sendable, Equatable {
    /// A log file already on disk.
    case file(URL)
    /// Log contents in memory, with the file name to send them under.
    case data(Data, fileName: String)
}

/// Where `DebugButton.sendLogs(logs:destination:)` sends the logs.
public struct DebugLogDestination: Sendable {
    let send: @MainActor @Sendable ([DebugLogFile]) async throws -> Void

    /// Sends the logs with your own closure, e.g. to attach them to a crash reporter.
    public static func custom(_ send: @escaping @MainActor @Sendable ([DebugLogFile]) async throws -> Void) -> DebugLogDestination {
        DebugLogDestination(send: send)
    }
}

public extension DebugButton {
    /// A "Send logs" button. When tapped, `logs` gathers the app's logs and `destination` sends them.
    /// An error thrown by either shows on the row.
    static func sendLogs(
        logs: @escaping @MainActor @Sendable () async throws -> [DebugLogFile],
        destination: DebugLogDestination
    ) -> DebugButton {
        DebugButton(DefaultTitle.sendLogs) {
            try await destination.send(logs())
        }
    }
}
