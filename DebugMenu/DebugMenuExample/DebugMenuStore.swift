//
//  DebugMenuStore.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2021-12-02.
//

import Foundation
import DebugMenu
import SwiftUI
import Combine


public class DebugMenuStore: BaseDebugDataSource {

    @UserDefault(key: "testToggle") var testToggle = true
    @UserDefault(key: "debugForceFoo") var debugForceFoo = false
    @Published var globalBool: Bool = false

    public static let shared = DebugMenuStore()

    init() {
        super.init()
        buildDebugMenu()
    }

    func buildDebugMenu() {
        let testButton = DebugButtonAction(title: "Test Button", action: { print("Button Tapped") })
        let testSubmenu = DebugSubmenuAction(title: "Test submenu", dataSource: TestDataSource())
        let testToggle = DebugToggleAction(title: "Test Toggle", toggle: $testToggle)
        let debugForceFooToggle = DebugToggleAction(title: "Debug Force Foo", toggle: $debugForceFoo)
        let toggleGlobalBool = DebugToggleAction(title: "Toggle Global Bool", toggle: Binding(get: {
            self.globalBool
        }, set: { value in
            self.globalBool = value
        }))

        self.addActions([
            testButton,
            testSubmenu,
            testToggle,
            debugForceFooToggle,
            toggleGlobalBool
        ])
    }

    public override var includeCommonOptions: Bool {
        true
    }
}
