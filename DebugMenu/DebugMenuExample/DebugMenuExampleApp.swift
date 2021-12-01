//
//  DebugMenuExampleApp.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import DebugMenu

@main
struct DebugMenuExampleApp: App {

    init() {
        buildDebugMenu()
    }

    func buildDebugMenu() {
        let testToggle = DebugActionType.toggle(action: DebugToggleAction(title: "Test Toggle",
                                                                          userDefaultsKey: "testKey",
                                                                          onToggleComplete: nil))
        let anotherToggle = DebugActionType.toggle(action: DebugToggleAction(title: "Another Toggle",
                                                                             userDefaultsKey: "secondKey",
                                                                             onToggleComplete: { value in  print("Toggled! \(value)")}))
        let testButton = DebugActionType.button(title: "Test Button", action: { print("Button Tapped") })

        let dataSource = TestDataSource()
        let testSubmenu = DebugActionType.submenu(action: DebugSubmenuAction(title: "Test submenu",
                                                                             dataSource: .constant(dataSource)))
        DebugMenuStore.shared.addAction(testToggle)
        DebugMenuStore.shared.addAction(anotherToggle)
        DebugMenuStore.shared.addAction(testButton)
        DebugMenuStore.shared.addAction(testSubmenu)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

public class TestDataSource: BaseDebugDataSource {

    public override var navigationTitle: String {
        "Submenu"
    }

    init() {
        super.init(actions: [.button(title: "Submenu option", action: { })])
    }
}

