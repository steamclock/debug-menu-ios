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

