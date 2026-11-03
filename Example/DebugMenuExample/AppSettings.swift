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

/// A server the app can run against. Add whatever else an environment needs (API keys, feature hosts) here.
struct AppEnvironment: DebugEnvironment {
    private static let customTitle = "Custom"

    let title: String
    let url: URL

    // Force unwraps are fine here: these are fixed literals, so a typo fails on first launch, not in the field.
    static let production = AppEnvironment(title: "Production", url: URL(string: "https://api.example.com")!)
    static let staging = AppEnvironment(title: "Staging", url: URL(string: "https://staging.api.example.com")!)
    static let development = AppEnvironment(title: "Development", url: URL(string: "http://localhost:8080")!)

    /// The environments the picker lists. A custom one shows up once it's chosen.
    static let presets = [production, staging, development]

    /// An environment for a server typed into the debug menu's custom URL field.
    static func custom(_ url: URL) -> AppEnvironment {
        AppEnvironment(title: customTitle, url: url)
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
