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
        DebugMenuStore.shared.addActions([
            .toggle(action: DebugToggleAction(title: "Test Toggle",
                                              userDefaultsKey: "testKey",
                                              onToggleComplete: nil)),
            .toggle(action: DebugToggleAction(title: "Another Toggle",
                                              userDefaultsKey: "secondKey",
                                              onToggleComplete: { value in  print("Toggled! \(value)")} )),
            .button(title: "Test Button", action: { print("Button Tapped") }),
            .submenu(action: DebugSubmenuAction(title: "Test submenu",
                                                dataSource: TestDataSource()))])
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

