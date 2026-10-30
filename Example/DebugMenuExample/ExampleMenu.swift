import DebugMenu
import SwiftUI

/// The whole debug menu. Both triggers in `ContentView` show it.
struct ExampleMenu: DebugMenuContent {
    let settings: AppSettings

    var body: DebugMenuGroup {
        DebugInfo.defaults
        DebugPicker.environment(options: AppEnvironment.allCases, optionTitle: \.title,
                                get: { settings.environment }, set: { settings.environment = $0 })
            .confirmation(.required("Switch environment?", message: "You'll be signed out."))
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
            ExperimentsMenu(settings: settings)
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

/// Values changed from outside the menu's own rows. The `@Observable` one updates by itself; the `UserDefaults`
/// one needs `send()`.
private struct ExperimentsMenu: DebugMenuContent {
    let settings: AppSettings

    var body: DebugMenuGroup {
        DebugSubmenu("Experiments") {
            DebugToggle("New checkout", isOn: Bindable(settings).isNewCheckoutEnabled)
            DebugToggle("Dark launch", get: { settings.isDarkLaunchEnabled }, set: { settings.isDarkLaunchEnabled = $0 })
            DebugCustom("Flip new checkout") {
                Button("Flip new checkout without send()") { settings.isNewCheckoutEnabled.toggle() }
            }
            DebugCustom("Flip dark launch") {
                Button("Flip dark launch, then send()") {
                    settings.isDarkLaunchEnabled.toggle()
                    DebugMenuChanges.shared.send()
                }
            }
        }
    }
}

/// A custom row: any SwiftUI view.
private struct CartStepper: View {
    private static let range = 0...20

    @Bindable var settings: AppSettings

    var body: some View {
        Stepper("Cart items: \(settings.cartItemCount)", value: $settings.cartItemCount, in: Self.range)
    }
}
