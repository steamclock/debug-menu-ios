# debug-menu-ios

DebugMenu is a debug menu for iOS apps. You declare it like a SwiftUI view:

1. List sections and rows.
2. Point each row at state that your app already has.
3. Attach the menu to a view with `.debugMenuTrigger()`.

Seven taps on that view open the menu.

The menu never stores your values. Rows read and write your values through `get`/`set` closures
(or a `Binding`). Thus you never keep a second copy of a setting in sync.

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
`https://github.com/steamclock/debug-menu-ios.git`. In a `Package.swift` file, add these lines:

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

Tap "Hello" seven times. The menu opens in a sheet. The sheet shows the build name, version,
device and iOS version. Below them, a "Features" section shows a toggle and a button.

The menu content is a result builder, like a SwiftUI view body. The menu rebuilds its content each
time the menu shows or changes. Thus `if` and `for` follow your app's current state.

## Rows

Every row takes a title first, then whatever else the row needs. The examples below come from the
example app. In the example app, `settings` is an `@Observable` model that the app owns.

### Toggle

A toggle reads a `Bool` with `get` and writes the `Bool` with `set`:

```swift
DebugToggle("Show all foos", get: { settings.showAllFoos }, set: { settings.showAllFoos = $0 })
```

If you have a `Binding`, pass it as `isOn:`:

```swift
DebugToggle("Show all foos", isOn: $showAllFoos)
```

Code that you would put in a `didSet` goes in `set`.

### Button

A button runs a closure. The closure can also be `async throws`. While the closure runs, the row
shows a spinner. When the closure finishes, the row shows a checkmark, or the error if the closure
threw one.

```swift
DebugButton("Refresh token") { try await settings.refreshToken() }
DebugButton("Sync (always fails)") { try await settings.sync() }
```

Use `role: .destructive` to make the row red. Use `confirmation:` to ask before the action runs:

```swift
DebugButton("Clear cache", role: .destructive, confirmation: .required("Clear the image cache?")) {
    settings.cachedImageCount = 0
}
```

`.required(_:message:confirmTitle:cancelTitle:)` also takes an optional message and button labels.
Toggles and pickers ask the same way with the `.confirmation(_:)` modifier:

```swift
DebugPicker.environment(options: AppEnvironment.presets,
                        get: { settings.environment }, set: { settings.environment = $0 })
    .confirmation(.required("Switch environment?", message: "You'll be signed out."))
```

### Picker

A picker chooses one value. The shortest form shows every case of an enum that conforms to
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

An info row shows a read-only value. A tap on the row copies the value to the clipboard.

```swift
DebugInfo("Cached images", value: "\(settings.cachedImageCount)")
```

The menu reads the value again each time the menu shows. If the value is `nil`, the row shows
"None".

### Custom rows

When no built-in row fits, show your own SwiftUI view. The row's ID and snapshots use the title to
name the row. `value:` is optional text. In snapshots, the `value:` text takes the place of the view.

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
- `.disabled(_:reason:)` dims the row. If you give a reason, the row shows the reason.
- `.id(_:)` sets the row's ID. For more about IDs, see [Snapshots and commands](#snapshots-and-commands).

The menu reads the conditions each time the menu shows.

## Sections and submenus

`DebugSection` groups rows under a header. `DebugSubmenu` is a row that pushes a nested menu. Both
take their content inline. You can nest them as deep as you like:

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

When part of a menu gets long, move that part into a type that conforms to `DebugMenuContent`.
`NetworkMenu` above is a type like this:

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

Rows read your values while the rows render. Thus SwiftUI keeps the rows current, the same way it
keeps your own views current. Changes through the menu's own rows appear immediately. Changes to
an `@Observable` model from anywhere else also appear immediately. For example, the cart stepper in
the example app is a custom row that changes `settings.cartItemCount` directly.

SwiftUI can't observe every kind of storage, though. One example is `UserDefaults` read through a
computed property. Sometimes code outside the menu changes a value like this while the menu is open.
In that case, call `DebugMenuChanges.shared.send()`. The menu then reads its values again:

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

You don't need `send()` after a change through a menu row. The menu sends the signal itself after
every command.

## Built-in rows

These are regular rows that already have a title and wiring. Add the ones you want.

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
whatever value iOS gives us.

### Environment, logging and send logs

```swift
DebugPicker.environment(options: AppEnvironment.presets,
                        get: { settings.environment }, set: { settings.environment = $0 })
DebugToggle.advancedLogging(get: { settings.isAdvancedLoggingEnabled }, set: { settings.isAdvancedLoggingEnabled = $0 })
DebugButton.sendLogs(logs: { settings.logFiles }, destination: .shareSheet)
```

- `DebugPicker.environment` is an "Environment" picker. Do the actual switch in `set`, for example
  sign out and use a new server. See [Environments](#environments) below.
- `DebugToggle.advancedLogging` is an "Advanced logging" toggle over your own setting.
- `DebugButton.sendLogs` is a "Send logs" button. Your `logs` closure returns `DebugLogFile`s:
  `.file(URL)` for a file on disk, or `.data(Data, fileName:)` for logs in memory.

### Environments

The environment picker takes your own type. The type must conform to `DebugEnvironment`, which
requires a `title` and a `url`. The picker shows each URL under its title. A struct is the shortest
way to write the type. If an environment needs more data (API keys, other hosts), add more
properties:

```swift
struct AppEnvironment: DebugEnvironment {
    let title: String
    let url: URL

    static let production = AppEnvironment(title: "Production", url: URL(string: "https://api.example.com")!)
    static let staging = AppEnvironment(title: "Staging", url: URL(string: "https://staging.api.example.com")!)
    static let presets = [production, staging]
}
```

To let people enter any server, like a local machine, pass `custom:`. The `custom:` closure turns
the entered URL into one of your environments:

```swift
DebugPicker.environment(options: AppEnvironment.presets,
                        get: { settings.environment }, set: { settings.environment = $0 },
                        custom: { AppEnvironment(title: "Custom", url: $0) })
```

The custom URL field is off unless you pass `custom:`. The field only accepts `http` and `https`
URLs with a host. After someone chooses a custom environment, the picker lists that environment with
the presets and shows it as selected.

### Send logs

`.shareSheet` is the only destination we ship. It shows the system share sheet, so you can mail,
AirDrop or save the logs. To send the logs somewhere else, use `.custom`:

```swift
DebugButton.sendLogs(
    logs: { [.file(URL.temporaryDirectory.appending(path: "app.log"))] },
    destination: .custom { logs in try await Telemetry.upload(logs) }
)
```

## Opening the menu

`.debugMenuTrigger` opens the menu in a sheet. By default, the gesture is seven taps with one finger.
You can change the count:

```swift
.debugMenuTrigger(taps: 10) { … }
```

You can also open the menu with a long press:

```swift
Text("Long press to open it with a password (\"debug\")")
    .padding()
    .contentShape(Rectangle())
    .debugMenuTrigger(longPressDuration: Self.longPressDuration, access: .passwordSHA256(Self.passwordHash)) {
        ExampleMenu(settings: settings)
    }
```

The gesture is on the view that has the trigger. Give that view a hit area big enough to find.

To show the menu yourself, use `DebugMenuView`. It takes the same content. Put the `DebugMenuView`
in a `NavigationStack`, because submenus and pickers push screens. `DebugMenuView` doesn't ask for a
password. Only the trigger asks for a password.

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

`.passwordSHA256` takes the hex SHA-256 hash of the password. Thus the password itself isn't in your
app. To make a hash, run this command in Terminal:

```bash
printf 'debug' | shasum -a 256
```

To check the password some other way, use `.custom`:

```swift
.debugMenuTrigger(taps: 10, access: .custom { $0 == "letmein" }) { … }
```

After someone enters the correct password, the menu stops asking, even after a relaunch. We store
an "unlocked" flag in `UserDefaults`. We never store the password. Deleting the app resets the flag.

## Snapshots and commands

`DebugMenu { }` builds a menu as plain data. You can inspect that data without any UI. This is
useful in unit tests. A remote debugger would also use this data later.

`snapshot()` describes the whole menu as it is right now. The snapshot is `Codable`. `snapshot()`
reads each row's current value through the row's `get`.

`dispatch(_:)` applies a `Codable` `DebugCommand` to a row, the same way a tap on the row would.
`dispatch(_:)` doesn't show confirmations. If the row has a confirmation, ask first.

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
picker with `custom:`), `.runAction` and `.runAsyncAction`. The result contains any error from an
async action.

A row ID is the titles on the row's path, joined with `/`. For example, a "Clear cache" button in a
"Cache" submenu in a "More" section has the ID `More/Cache/Clear cache`. Row IDs stay the same on
every launch and device. If a title changes at runtime, or two rows share a title, set the ID
yourself with `.id(_:)`. Sections and submenus also take `.id(_:)`:

```swift
DebugSection("Advanced") {
    DebugInfo("Session", value: "abc").id("session")
}.id("advanced")
```

A picker option's ID is `String(describing:)` of the option's value. Thus the ID of an enum case is
the case name.

## Example app

`Example/` has an app that uses every feature. [XcodeGen](https://github.com/yonaskolb/XcodeGen)
generates the Xcode project:

```bash
cd Example
xcodegen generate
open DebugMenuExample.xcodeproj
```

The menu is in `Example/DebugMenuExample/ExampleMenu.swift`.

## Upgrading from 1.x

2.0 is a rewrite with a new API. It has no compatibility layer, and it needs iOS 17. Most 1.x menus
should get shorter after the upgrade. This table shows the 2.0 replacement for each 1.x piece:

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

2.0 has no row types for text-field alerts or host controllers. A custom row covers both:

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

1.x toggles stored their values in `UserDefaults` under the `key` you gave them. To keep those
values, read the same key, for example with `@AppStorage("showFoosKey")`.
