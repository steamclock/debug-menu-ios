import Foundation

private enum DefaultTitle {
    static let environment = "Environment"
    static let advancedLogging = "Advanced logging"
    static let sendLogs = "Send logs"
}

/// A server the app can run against, for `DebugPicker.environment`. Conform the app's own environment type, and
/// give it whatever else an environment needs alongside its title and URL.
public protocol DebugEnvironment: Hashable, Sendable {
    /// The environment's name, like "Staging".
    var title: String { get }
    /// The server the environment points at, shown under the title.
    var url: URL { get }
}

public extension DebugPicker {
    /// An "Environment" picker. `set` is where the app switches, e.g. by signing out and pointing at a new server.
    ///
    /// The custom URL field is off by default. Pass `custom` to turn it on: it turns a typed-in `http` or `https`
    /// URL into one of the app's environments, which then goes to `set` like any other choice.
    static func environment<Value: DebugEnvironment>(
        options: [Value],
        get: @escaping @MainActor @Sendable () -> Value,
        set: @escaping @MainActor @Sendable (Value) -> Void,
        custom: (@MainActor @Sendable (URL) -> Value)? = nil
    ) -> DebugPicker {
        let configuration = DebugPickerConfiguration(
            options: options,
            title: \.title,
            subtitle: \.url.absoluteString,
            customURL: custom,
            get: get,
            set: set
        )
        return DebugPicker(DefaultTitle.environment, configuration: configuration)
    }
}

extension URL {
    private static let serverSchemes: Set<String> = ["http", "https"]

    /// Whether this is something a custom environment can point at: an `http` or `https` URL with a host.
    var isServerURL: Bool {
        scheme.map { Self.serverSchemes.contains($0.lowercased()) } == true && host() != nil
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
