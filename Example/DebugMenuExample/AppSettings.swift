import DebugMenu
import Foundation

/// The app's own state. The debug menu reads and writes it, but never stores a copy.
@Observable
@MainActor
final class AppSettings {
    private static let fakeNetworkDelay = Duration.seconds(1)
    private static let darkLaunchKey = "isDarkLaunchEnabled"

    var environment = AppEnvironment.production
    var isAdvancedLoggingEnabled = false
    var showAllFoos = false
    var logLevel = LogLevel.info
    var pageSize = 25
    var isSlowNetworkEnabled = false
    var userID: String? = "user-1234"
    var cachedImageCount = 42
    var cartItemCount = 2
    var isNewCheckoutEnabled = false

    /// Stored in `UserDefaults`, which SwiftUI can't observe. Changing it outside the menu needs
    /// `DebugMenuChanges.shared.send()` before an open menu shows it.
    var isDarkLaunchEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.darkLaunchKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.darkLaunchKey) }
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
        try await Task.sleep(for: Self.fakeNetworkDelay)
    }

    func sync() async throws {
        try await Task.sleep(for: Self.fakeNetworkDelay)
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

/// The servers the app can run against. Add whatever else an environment needs (API keys, feature hosts) here.
enum AppEnvironment: DebugEnvironment {
    case production
    case staging
    case development
    /// A server typed into the debug menu's custom URL field.
    case custom(URL)

    /// The environments the picker lists. A custom one shows up once it's chosen.
    static let presets: [AppEnvironment] = [.production, .staging, .development]

    private static let productionURL = serverURL("https://api.example.com")
    private static let stagingURL = serverURL("https://staging.api.example.com")
    private static let developmentURL = serverURL("http://localhost:8080")

    var title: String {
        switch self {
        case .production: "Production"
        case .staging: "Staging"
        case .development: "Development"
        case .custom: "Custom"
        }
    }

    var url: URL {
        switch self {
        case .production: Self.productionURL
        case .staging: Self.stagingURL
        case .development: Self.developmentURL
        case .custom(let url): url
        }
    }

    private static func serverURL(_ string: StaticString) -> URL {
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid server URL literal: \(string)")
        }
        return url
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
