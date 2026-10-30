import DebugMenu
import Foundation

/// The app's own state. The debug menu reads and writes it, but never stores a copy.
@MainActor
final class AppSettings: ObservableObject {
    private static let fakeNetworkDelay: UInt64 = 1_000_000_000

    @Published var environment = AppEnvironment.production
    @Published var isAdvancedLoggingEnabled = false
    @Published var showAllFoos = false
    @Published var logLevel = LogLevel.info
    @Published var pageSize = 25
    @Published var isSlowNetworkEnabled = false
    @Published var userID: String? = "user-1234"
    @Published var cachedImageCount = 42
    /// The cart stepper is a custom row, so its changes don't go through the menu's commands.
    /// Tell an open menu about them, so rows that read the cart (like "Clear cart") update too.
    @Published var cartItemCount = 2 {
        didSet { DebugMenuChanges.shared.send() }
    }

    let foos = [
        Foo(id: "foo-1", name: "First foo", status: "Active"),
        Foo(id: "foo-2", name: "Second foo", status: "Archived")
    ]

    var logFiles: [DebugLogFile] {
        let log = "environment=\(environment) logLevel=\(logLevel) user=\(userID ?? "none")\n"
        return [.data(Data(log.utf8), fileName: "example.log")]
    }

    func refreshToken() async throws {
        try await Task.sleep(nanoseconds: Self.fakeNetworkDelay)
    }

    func sync() async throws {
        try await Task.sleep(nanoseconds: Self.fakeNetworkDelay)
        throw SyncError.serverUnavailable
    }
}

enum SyncError: Error {
    case serverUnavailable
}

struct Foo: Sendable {
    let id: String
    let name: String
    let status: String
}

enum AppEnvironment: String, CaseIterable, Sendable {
    case production
    case staging
    case development

    var title: String {
        rawValue.capitalized
    }
}

enum LogLevel: String, DebugPickerValue {
    case error
    case info
    case verbose

    var debugTitle: String {
        rawValue.capitalized
    }

    var debugSubtitle: String? {
        self == .verbose ? "Logs every request" : nil
    }
}

/// An iOS 17 `@Observable` model, next to the `ObservableObject` above.
///
/// It's a shared instance because an iOS 15 app can't have a stored property of an iOS 17 type.
@available(iOS 17, *)
@Observable
@MainActor
final class ExperimentFlags {
    static let shared = ExperimentFlags()

    var isNewCheckoutEnabled = false
}
