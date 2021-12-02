//
//  DebugMenuStore.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2021-12-02.
//

import Foundation
import DebugMenu

public class DebugMenuStore: BaseDebugDataSource {

    public static let shared = DebugMenuStore()

    init() {
        let testToggle = DebugToggleAction(title: "Test Toggle", userDefaultsKey: "testKey")
        let anotherToggle = DebugToggleAction(title: "Another Toggle",
                                              userDefaultsKey: "secondKey",
                                              onToggleComplete: { value in  print("Toggled! \(value)")})
        let testButton = DebugButtonAction(title: "Test Button", action: { print("Button Tapped") })
        let testSubmenu = DebugSubmenuAction(title: "Test submenu", dataSource: TestDataSource())
        super.init(actions: [testToggle,
                             anotherToggle,
                             testButton,
                             testSubmenu])
    }
}
