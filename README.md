# debug-menu-ios

A debug menu for iOS apps that you declare like a SwiftUI view. You list sections and rows, point
each row at state your app already has, and attach the menu to a view with `.debugMenuTrigger()`.
Seven taps on that view open it.

The menu never stores your values. Rows read and write through `get`/`set` closures (or a
`Binding`), so there's no second copy of a setting to keep in sync.

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Rows](#rows)
- [Sections and submenus](#sections-and-submenus)
- [Keeping the menu up to date](#keeping-the-menu-up-to-date)
- [Built-in rows](#built-in-rows)
- [Opening the menu](#opening-the-menu)
- [Password](#password)
- [Snapshots and commands](#snapshots-and-commands)
- [Example app](#example-app)
- [Upgrading from 1.x](#upgrading-from-1x)

## Requirements

- iOS 17 or later.
- Xcode 16 or later (swift-tools 6.0). The package builds in Swift 6 language mode.
- No other dependencies.

## Installation

Add the package with Swift Package Manager. In Xcode, use **File > Add Package Dependencies** with
`https://github.com/steamclock/debug-menu-ios.git`. In a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/steamclock/debug-menu-ios.git", from: "2.0.0")
],
targets: [
    .target(name: "MyApp", dependencies: [.product(name: "DebugMenu", package: "debug-menu-ios")])
]
```

## Quick start

```swift
import DebugMenu
import SwiftUI

struct ContentView: View {
    @AppStorage("showAllFoos") private var showAllFoos = false

    var body: some View {
        Text("Hello")
            .debugMenuTrigger {
                DebugInfo.defaults
                DebugSection("Features") {
                    DebugToggle("Show all foos", isOn: $showAllFoos)
                    DebugButton("Reset onboarding") { Onboarding.reset() }
                }
            }
    }
}
```

Tap "Hello" seven times and the menu opens in a sheet, showing the build name, version, device and
iOS version, then a "Features" section with a toggle and a button.

The menu content is a result builder, like a SwiftUI view body. It's rebuilt each time the menu
shows or changes, so `if` and `for` follow your app's current state.

## Rows

Every row takes a title first, then whatever it needs. The examples below come from the example app,
where `settings` is an `@Observable` model the app owns.

### Toggle

A toggle reads a `Bool` with `get` and writes it with `set`:

```swift
DebugToggle("Show all foos", get: { settings.showAllFoos }, set: { settings.showAllFoos = $0 })
```

If you have a `Binding`, pass it as `isOn:`:

```swift
DebugToggle("Show all foos", isOn: $showAllFoos)
```

Anything you'd have done in a `didSet` goes in `set`.

### Button

A button runs a closure. An `async throws` closure works too: the row shows a spinner while it runs,
then a checkmark, or the error if it threw.

```swift
DebugButton("Refresh token") { try await settings.refreshToken() }
DebugButton("Sync (always fails)") { try await settings.sync() }
```

Use `role: .destructive` for a red row, and `confirmation:` to ask before the action runs:

```swift
DebugButton("Clear cache", role: .destructive, confirmation: .required("Clear the image cache?")) {
    settings.cachedImageCount = 0
}
```

`.required(_:message:confirmTitle:cancelTitle:)` takes an optional message and button labels too.
Toggles and pickers ask the same way with the `.confirmation(_:)` modifier:

```swift
DebugPicker.environment(options: AppEnvironment.presets,
                        get: { settings.environment }, set: { settings.environment = $0 })
    .confirmation(.required("Switch environment?", message: "You'll be signed out."))
```

### Picker

A picker chooses one value. The shortest form is over every case of an enum that conforms to
`DebugPickerValue`:

```swift
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
```

```swift
DebugPicker("Log level", get: { settings.logLevel }, set: { settings.logLevel = $0 })
```

`debugSubtitle` is optional. To pick from an explicit list instead, pass `options:` and a title for
each option:

```swift
DebugPicker("Page size", options: [10, 25, 50], optionTitle: { "\($0) items" },
            get: { settings.pageSize }, set: { settings.pageSize = $0 })
```

Both forms also take a `selection:` `Binding` in place of `get`/`set`:

```swift
DebugPicker("Log level", selection: $logLevel)
```

### Info

An info row shows a read-only value. Tapping it copies the value to the clipboard.

```swift
DebugInfo("Cached images", value: "\(settings.cachedImageCount)")
```

The value is read each time the menu shows, not once. A `nil` value shows "None".

### Custom rows

When no built-in row fits, show your own SwiftUI view. The title names the row in its ID and in
snapshots, and `value:` is optional text that stands in for the view there.

```swift
DebugCustom("Cart items", value: "\(settings.cartItemCount)") { CartStepper(settings: settings) }
```

```swift
private struct CartStepper: View {
    private static let range = 0...20

    @Bindable var settings: AppSettings

    var body: some View {
        Stepper("Cart items: \(settings.cartItemCount)", value: $settings.cartItemCount, in: Self.range)
    }
}
```

### Row modifiers

All rows take these modifiers:

```swift
DebugPicker("Log level", get: { settings.logLevel }, set: { settings.logLevel = $0 })
    .help("Verbose logging slows the app down.")
DebugInfo("User ID", value: settings.userID).hidden(settings.userID == nil)
DebugButton("Clear cart") { settings.cartItemCount = 0 }
    .disabled(settings.cartItemCount == 0, reason: "The cart is empty")
```

- `.help(_:)` adds a line of text under the title.
- `.hidden(_:)` hides the row while the condition is true.
- `.disabled(_:reason:)` greys the row out, and shows the reason if you give one.
- `.id(_:)` sets the row's ID. More on that in [Snapshots and commands](#snapshots-and-commands).

The conditions are read each time the menu shows.

## Sections and submenus

`DebugSection` groups rows under a header. `DebugSubmenu` is a row that pushes a nested menu. Both
take their content inline, and nest as deep as you like:

```swift
DebugSection("More") {
    DebugSubmenu("Cache") {
        DebugInfo("Cached images", value: "\(settings.cachedImageCount)")
        DebugButton("Clear cache", role: .destructive, confirmation: .required("Clear the image cache?")) {
            settings.cachedImageCount = 0
        }
    }
    NetworkMenu(settings: settings)
}
```

When part of a menu gets long, move it into a type that conforms to `DebugMenuContent`. That's what
`NetworkMenu` above is:

```swift
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
```

`if`, `if/else`, `if #available` and `for` all work in the builder:

```swift
DebugToggle("Show all foos", get: { settings.showAllFoos }, set: { settings.showAllFoos = $0 })
if settings.showAllFoos {
    for foo in settings.foos {
        DebugInfo(foo.name, value: foo.status).id(foo.id)
    }
}
```

## Keeping the menu up to date

Rows read your values while they render, so SwiftUI keeps them current the same way it keeps your
own views current. Changes made through the menu's own rows show up right away. So do changes from
anywhere else to an `@Observable` model, like the cart stepper in the example app, which is a custom
row that changes `settings.cartItemCount` directly.

SwiftUI can't see every kind of storage, though. When a value lives somewhere it can't observe, like
`UserDefaults` read through a computed property, and something outside the menu changes it while the
menu is open, call `DebugMenuChanges.shared.send()` so the menu reads its values again:

```swift
var isDarkLaunchEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: Self.darkLaunchKey) }
    set { UserDefaults.standard.set(newValue, forKey: Self.darkLaunchKey) }
}
```

```swift
Button("Flip dark launch, then send()") {
    settings.isDarkLaunchEnabled.toggle()
    DebugMenuChanges.shared.send()
}
```

You don't need `send()` after a change made through a menu row. The menu sends it after every
command.

## Built-in rows

These are regular rows with the title and wiring filled in. Add the ones you want.

### Build and device info

`DebugInfo.defaults` adds four info rows: build name, build version, device name, and iOS version.
You can also add them one at a time:

```swift
DebugInfo.buildVersion
DebugInfo.systemVersion
```

The others are `DebugInfo.buildName` and `DebugInfo.deviceName`.

The device name comes from `UIDevice.name`. That's only the model, like "iPhone", unless your app
has the `com.apple.developer.device-information.user-assigned-device-name` entitlement. We show
whatever iOS gives us.

### Environment, logging and send logs

```swift
DebugPicker.environment(options: AppEnvironment.presets,
                        get: { settings.environment }, set: { settings.environment = $0 })
DebugToggle.advancedLogging(get: { settings.isAdvancedLoggingEnabled }, set: { settings.isAdvancedLoggingEnabled = $0 })
DebugButton.sendLogs(logs: { settings.logFiles }, destination: .shareSheet)
```

- `DebugPicker.environment` is an "Environment" picker. Do the actual switch (sign out, point at a
  new server) in `set`. See [Environments](#environments) below.
- `DebugToggle.advancedLogging` is an "Advanced logging" toggle over your own setting.
- `DebugButton.sendLogs` is a "Send logs" button. Your `logs` closure returns `DebugLogFile`s:
  `.file(URL)` for a file on disk, or `.data(Data, fileName:)` for logs in memory.

### Environments

The environment picker takes your own type, as long as it conforms to `DebugEnvironment`, which needs a
`title` and a `url`. The picker shows each URL under its title. A struct keeps it short, and anything
else an environment needs (API keys, other hosts) is another property:

```swift
struct AppEnvironment: DebugEnvironment {
    let title: String
    let url: URL

    static let production = AppEnvironment(title: "Production", url: URL(string: "https://api.example.com")!)
    static let staging = AppEnvironment(title: "Staging", url: URL(string: "https://staging.api.example.com")!)
    static let presets = [production, staging]
}
```

To let people type in any server, like a local machine, pass `custom:`. It turns the URL they type
into one of your environments:

```swift
DebugPicker.environment(options: AppEnvironment.presets,
                        get: { settings.environment }, set: { settings.environment = $0 },
                        custom: { AppEnvironment(title: "Custom", url: $0) })
```

The custom URL field is off unless you pass `custom:`. It only accepts `http` and `https` URLs with a
host. Once a custom environment is chosen, it's listed with the presets and shows as selected.

### Send logs

`.shareSheet` is the only destination we ship. It shows the system share sheet, so you can mail,
AirDrop or save the logs. To send them somewhere else, use `.custom`:

```swift
DebugButton.sendLogs(
    logs: { [.file(URL.temporaryDirectory.appending(path: "app.log"))] },
    destination: .custom { logs in try await Telemetry.upload(logs) }
)
```

## Opening the menu

`.debugMenuTrigger` opens the menu in a sheet. By default that's seven taps with one finger. You can
change the count:

```swift
.debugMenuTrigger(taps: 10) { … }
```

Or open it with a long press instead:

```swift
Text("Long press to open it with a password (\"debug\")")
    .padding()
    .contentShape(Rectangle())
    .debugMenuTrigger(longPressDuration: Self.longPressDuration, access: .passwordSHA256(Self.passwordHash)) {
        ExampleMenu(settings: settings)
    }
```

The gesture is on the view you attach it to, so give that view a hit area big enough to find.

If you'd rather show the menu yourself, `DebugMenuView` takes the same content. Put it in a
`NavigationStack`, since submenus and pickers push screens. It doesn't ask for a
password; that's part of the trigger.

```swift
struct SettingsScreen: View {
    @State private var isShowingDebugMenu = false

    var body: some View {
        Button("Debug menu") { isShowingDebugMenu = true }
            .sheet(isPresented: $isShowingDebugMenu) {
                NavigationStack {
                    DebugMenuView {
                        DebugInfo.defaults
                    }
                }
            }
    }
}
```

## Password

There's no password by default. To add one, pass an `access` policy to the trigger, as in the long
press example above. The menu asks for the password after the gesture.

`.passwordSHA256` takes the hex SHA-256 hash of the password, so the password itself isn't in your
app. You can make one in Terminal:

```bash
printf 'debug' | shasum -a 256
```

To check the password some other way, use `.custom`:

```swift
.debugMenuTrigger(taps: 10, access: .custom { $0 == "letmein" }) { … }
```

Once someone enters the right password, the menu stops asking, including after a relaunch. We store
an "unlocked" flag in `UserDefaults`, never the password. Deleting the app resets it.

## Snapshots and commands

Building a menu with `DebugMenu { }` gives you plain data you can inspect without any UI. That's
handy in unit tests, and it's what a remote debugger would use later.

`snapshot()` describes the whole menu as it is right now. It's `Codable`, and it reads each row's
current value through its `get`. `dispatch(_:)` applies a `Codable` `DebugCommand` to a row, the same
way tapping it would. Confirmations aren't shown, so ask first if the row has one.

```swift
let menu = DebugMenu {
    ExampleMenu(settings: settings)
}
let json = try JSONEncoder().encode(menu.snapshot())

let result = await menu.dispatch(.setToggle(rowID: "Features/Show all foos", isOn: true))
if case .failure(let error) = result {
    print("Couldn't set the toggle: \(error)")
}
```

The commands are `.setToggle`, `.selectOption` (by option ID), `.setCustomURL` (for an environment
picker with `custom:`), `.runAction` and `.runAsyncAction`. An async action's error comes back in the
result.

Row IDs are the titles on the row's path, joined with `/`. A "Clear cache" button in a "Cache"
submenu in a "More" section is `More/Cache/Clear cache`. They're the same on every launch and device.
If a title changes at runtime, or two rows share one, set the ID yourself with `.id(_:)`. Sections and
submenus take `.id(_:)` too:

```swift
DebugSection("Advanced") {
    DebugInfo("Session", value: "abc").id("session")
}.id("advanced")
```

Picker option IDs are `String(describing:)` of each value, so an enum case's ID is its name.

## Example app

`Example/` has an app that uses every feature. The Xcode project is generated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd Example
xcodegen generate
open DebugMenuExample.xcodeproj
```

The menu is in `Example/DebugMenuExample/ExampleMenu.swift`.

## Upgrading from 1.x

2.0 is a rewrite with a new API, and there's no compatibility layer. It needs iOS 17. Most 1.x menus should get shorter
along the way. Here's where each 1.x piece went:

| 1.x | 2.0 |
|-----|-----|
| A `BaseDebugDataSource` subclass (`DebugMenuDataSource`) | A `DebugMenu` builder, either inline in `.debugMenuTrigger { }` or in a `DebugMenuContent` type |
| `DebugSection(title:actions:)` | `DebugSection("Title") { … }` |
| `@DebugToggle(title:key:didSet:)` | Your own property (`@AppStorage`, `UserDefaults`, a model) and `DebugToggle(_:get:set:)` or `DebugToggle(_:isOn:)`. `didSet` work goes in `set`. |
| `DebugButtonAction` | `DebugButton` |
| `DebugSubmenuAction(dataSource:)` | `DebugSubmenu("Title") { … }`, or a `DebugMenuContent` type |
| `DebugNavigationAction` | `DebugCustom` with a `NavigationLink` |
| `DebugTextFieldAlertAction` | `DebugCustom` with your own text field |
| `DebugHostControllerAction` | `DebugCustom` with a `NavigationLink` to your screen (wrap a view controller in `UIViewControllerRepresentable`) |
| Switchcraft endpoint switching | `DebugPicker.environment` over your own `DebugEnvironment` type, with `custom:` for typed-in URLs |
| `includeCommonOptions` | `DebugInfo.defaults` |
| `isLoading` and `debugAlert` | An async `DebugButton`, which shows progress and errors itself |
| `DebugMenuAccessConfig(passwordSHA256:longPressDuration:)` and `.debugMenuToggle(config:isVisible:)` | `.debugMenuTrigger(longPressDuration:access: .passwordSHA256(…))` |
| `DebugMenuView(dataSource:)` | `DebugMenuView { … }` |

Text-field alerts and host controllers are gone as row types. A custom row covers both:

```swift
struct RedeemCodeRow: View {
    @State private var code = ""

    var body: some View {
        HStack {
            TextField("Promo code", text: $code)
            Button("Redeem") { PromoCodes.redeem(code) }
                .disabled(code.isEmpty)
        }
    }
}
```

```swift
DebugCustom("Redeem code") { RedeemCodeRow() }
DebugCustom("Switch endpoint") {
    NavigationLink("Switch endpoint") { EndpointPicker() }
}
```

1.x toggles stored their values in `UserDefaults` under the `key` you gave them. If you want to keep
those values, read the same key, for example with `@AppStorage("showFoosKey")`.
