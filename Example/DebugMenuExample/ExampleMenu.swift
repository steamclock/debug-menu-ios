import DebugMenu
import SwiftUI

/// The whole debug menu. Both triggers in `ContentView` show it.
struct ExampleMenu: DebugMenuContent {
    let settings: AppSettings

    var body: DebugMenuGroup {
        DebugInfo.defaults
        DebugPicker.environment(options: AppEnvironment.allCases, optionTitle: \.title,
                                get: { settings.environment }, set: { settings.environment = $0 })
        DebugToggle.advancedLogging(get: { settings.isAdvancedLoggingEnabled }, set: { settings.isAdvancedLoggingEnabled = $0 })
        DebugButton.sendLogs(logs: { settings.logFiles }, destination: .shareSheet)

        DebugSection("Features") {
            DebugToggle("Show all foos", get: { settings.showAllFoos }, set: { settings.showAllFoos = $0 })
            if settings.showAllFoos {
                for foo in settings.foos {
                    DebugInfo(foo.name, value: foo.status).id(foo.id)
                }
            }
            DebugPicker("Log level", get: { settings.logLevel }, set: { settings.logLevel = $0 })
                .help("Verbose logging slows the app down.")
        }

        DebugSection("Account") {
            DebugInfo("User ID", value: settings.userID).hidden(settings.userID == nil)
            DebugButton("Refresh token") { try await settings.refreshToken() }
            DebugButton("Sync (always fails)") { try await settings.sync() }
            DebugButton("Sign out", role: .destructive, confirmation: .required("Sign out?")) { settings.userID = nil }
                .disabled(settings.userID == nil, reason: "Already signed out")
        }

        DebugSection("Cart") {
            DebugCustom("Cart items", value: "\(settings.cartItemCount)") { CartStepper(settings: settings) }
            DebugButton("Clear cart") { settings.cartItemCount = 0 }
                .disabled(settings.cartItemCount == 0, reason: "The cart is empty")
        }

        DebugSection("More") {
            DebugSubmenu("Cache") {
                DebugInfo("Cached images", value: "\(settings.cachedImageCount)")
                DebugButton("Clear cache", role: .destructive, confirmation: .required("Clear the image cache?")) {
                    settings.cachedImageCount = 0
                }
            }
            NetworkMenu(settings: settings)
            if #available(iOS 17, *) {
                ExperimentsMenu(flags: .shared)
            }
        }
    }
}

/// A submenu moved into its own type, with another submenu nested inline.
private struct NetworkMenu: DebugMenuContent {
    let settings: AppSettings

    var body: DebugMenuGroup {
        DebugSubmenu("Network") {
            DebugToggle("Simulate slow network", get: { settings.isSlowNetworkEnabled }, set: { settings.isSlowNetworkEnabled = $0 })
            DebugSubmenu("Paging") {
                DebugPicker("Page size", options: [10, 25, 50], optionTitle: { "\($0) items" },
                            get: { settings.pageSize }, set: { settings.pageSize = $0 })
            }
        }
    }
}

/// Rows over an `@Observable` model. On iOS 17 they should update when the model changes, without `send()`.
@available(iOS 17, *)
private struct ExperimentsMenu: DebugMenuContent {
    let flags: ExperimentFlags

    var body: DebugMenuGroup {
        DebugSubmenu("Experiments") {
            DebugToggle("New checkout", isOn: Bindable(flags).isNewCheckoutEnabled)
            DebugCustom("Flip from outside the menu") {
                Button("Flip new checkout without send()") { flags.isNewCheckoutEnabled.toggle() }
            }
        }
    }
}

/// A custom row: any SwiftUI view.
private struct CartStepper: View {
    private static let range = 0...20

    @ObservedObject var settings: AppSettings

    var body: some View {
        Stepper("Cart items: \(settings.cartItemCount)", value: $settings.cartItemCount, in: Self.range)
    }
}
