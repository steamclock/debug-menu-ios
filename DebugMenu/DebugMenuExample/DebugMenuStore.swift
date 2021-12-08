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
    
    @DebugToggle(key: "debugForceFooKey") var debugForceFoo = false
    @DebugToggle(title: "Show All Foos", key: "showFoosKey") var showAllFoos = false
    @DebugToggle(title: "In Memory Flag") var inMemoryFlag = false
    
    public static let shared = DebugMenuStore()
    
    init() {
        super.init()
        buildDebugMenu()
    }
    
    func buildDebugMenu() {
        let testButton = DebugButtonAction(title: "Test Button", action: { print("Button Tapped") })
        let testSubmenu = DebugSubmenuAction(title: "Test submenu", dataSource: TestDataSource())
        
        let debugForceFooAction = DebugToggleAction(title: $debugForceFoo.displayTitle, toggle: Binding(get: { self.debugForceFoo }, set: { self.debugForceFoo = $0 }))
        let showFoosAction = DebugToggleAction(title: $showAllFoos.displayTitle, toggle: Binding(get: { self.showAllFoos }, set: { self.showAllFoos = $0 }))
        let inMemoryAction = DebugToggleAction(title: $inMemoryFlag.displayTitle, toggle: Binding(get: { self.inMemoryFlag }, set: { self.inMemoryFlag = $0 }))
        
        self.addActions([
            testButton,
            testSubmenu,
            debugForceFooAction,
            showFoosAction,
            inMemoryAction
        ])
    }
    
    public override var includeCommonOptions: Bool {
        true
    }
}
