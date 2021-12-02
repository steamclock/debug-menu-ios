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
        let testToggle = DebugToggleAction(title: "Test Toggle", userDefaultsKey: "testKey")
        let anotherToggle = DebugToggleAction(title: "Another Toggle",
                                              userDefaultsKey: "secondKey",
                                              onToggleComplete: { value in  print("Toggled! \(value)")})
        let testButton = DebugButtonAction(title: "Test Button", action: { print("Button Tapped") })
        let testSubmenu = DebugSubmenuAction(title: "Test submenu", dataSource: TestDataSource())
        DebugMenuStore.shared.addActions([
            testToggle,
            anotherToggle,
            testButton,
            testSubmenu
        ])
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
        super.init(actions: [DebugButtonAction(title: "Submenu option", action: { })])
    }
}

