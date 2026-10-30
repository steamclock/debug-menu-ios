import DebugMenu
import SwiftUI

@main
struct DebugMenuExampleApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
        }
    }
}

struct ContentView: View {
    /// SHA-256 of "debug", the long-press menu's password.
    private static let passwordHash = "0b8e9e995d8d77f1e4770f0f79665aee6f3f70247b3735422daba73df4c3096f"
    private static let longPressDuration: TimeInterval = 1

    let settings: AppSettings

    var body: some View {
        VStack(spacing: 32) {
            Text("Environment: \(settings.environment.title)")
            Text("Tap 7 times to open the debug menu")
                .padding()
                .contentShape(Rectangle())
                .debugMenuTrigger { ExampleMenu(settings: settings) }
            Text("Long press to open it with a password (\"debug\")")
                .padding()
                .contentShape(Rectangle())
                .debugMenuTrigger(longPressDuration: Self.longPressDuration, access: .passwordSHA256(Self.passwordHash)) {
                    ExampleMenu(settings: settings)
                }
        }
        .multilineTextAlignment(.center)
    }
}
