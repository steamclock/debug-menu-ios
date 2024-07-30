# debug-menu-ios

## Introduction
Debug-menu-iOS allows you to quickly setup a flexible and password-protected debug menu to your iOS app!

Note: The debug menu is designed to be used within SwiftUI views.

## Installation

### Add via SPM

```bash
https://github.com/steamclock/debug-menu-ios.git
```

### Setup

Define a data source for your debug menu where you will setup all of your debug actions. 
The only requirement is to subclass `BaseDebugDataSource`.

``` Swift
import DebugMenu

public class DebugMenuDataSource: BaseDebugDataSource {

    // Custom property wrapper for toggles
    @DebugToggle(title: "Show All Foos", key: "showFoosKey") var showAllFoos = false

    // Group actions in sections

    lazy var toggleSection: DebugSection = {
        DebugSection(title: "Toggles", actions: [$showAllFoos.action])
    }()

    lazy var buttonSection: DebugSection = {
        let testButton = DebugButtonAction(title: "Test Button", action: { print("Button Tapped") })

        return DebugSection(title: "Buttons", actions: [testButton])
    }()

    private init() {
        super.init()
        self.addSections([toggleSection, buttonSection])
    }
}
```

## Displaying the debug menu
``` Swift
struct MainView: View {

    @StateObject var debugMenuDataSource = DebugMenuDataSource()

    var body: some View {
        NavigationView {
           NavigationLink("Open Debug Menu!") {
                DebugMenuView(dataSource: debugMenuDataSource)
           }
        }
    }
}
```

## Password protecting your debug menu

Your password will be a SHA256 encoded string of your choosing. Generate one [here](https://tools.keycdn.com/sha256-online-generator)

Add a flag to your `DebugMenuDataSource` to handle the menus visibility, as well as a `DebugMenuAccessConfig` with your SHA256 encoded password and a longPressDuration for triggering a password-entry alert.

``` Swift

@Published public var isMenuEntryPointVisible = false

let config = DebugMenuAccessConfig(passwordSHA256: "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8", longPressDuration: 2.0)

``` 

### Handling visibility

``` Swift
List {
    if debugMenuDataSource.isVisible {
        NavigationLink("Open Debug Menu!") {
            DebugMenuView(dataSource: debugMenuDataSource)
        }
    }

    // The view to long press on that triggers the password-entry alert
    Text("Debug Hidden Entry")
        .debugMenuToggle(
            config: debugMenuDataSource.config,
            isVisible: $debugMenuDataSource.isVisible
        )
}
```

You now have a fully functional debug menu with a password protected entry point!

## Supported actions

DebugButtonAction - Define an action closure

DebugNavigationAction - Pushed to provided destination

DebugTextFieldAlertAction - Presents a text field alert given provided DebugTextFieldAlert

DebugSubmenuAction - Presents another debug menu given a provided BaseDebugDataSource

DebugHostControllerAction - Exposes a UIHostingController that you can present from (Built-in functionality to present various endpoints using [Switchcraft](https://github.com/steamclock/switchcraft))

DebugToggleAction - A toggle action (Automatically created in @DebugToggle.action)

## Debug Toggle property wrapper

SwiftUI automatically observes the state of your @DebugToggle and updates the view when it changes.

You can pass in a title, a UserDefaults key, a UserDefaults store (defaults to .standard), and a closure to handle additional actions on didSet.

If you don't provide a key the value will only be stored in memory. 

A `DebugToggleAction` is conveniently created for you within the property wrapper and is accessible via referencing your `toggle.action`

``` Swift 
@DebugToggle(key: "debugForceFooKey", didSet: debugForceFooSet) var debugForceFoo = false
@DebugToggle(title: "Show All Foos", key: "showFoosKey") var showAllFoos = false
@DebugToggle(title: "In Memory Flag") var inMemoryFlag = false

lazy var toggleSection: DebugSection = {
    DebugSection(title: "Toggles", actions: [$debugForceFoo.action, $showAllFoos.action, $inMemoryFlag.action])
}()
```

Have fun debugging! 🚀
