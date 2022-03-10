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

    @Published public var forceShow = false
    @Published public var isVisible = false

    public static let shared = DebugMenuStore()

    let config = DebugMenuAccessConfig(passwordSHA256: "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", longPressDuration: 2.0)
    
    init() {
        super.init()
        buildDebugMenu()
    }
    
    func buildDebugMenu() {
        let testButton = DebugButtonAction(title: "Test Button", action: { print("Button Tapped") })
        let testSubmenu = DebugSubmenuAction(title: "Test submenu", dataSource: TestDataSource())

        let testAlert = DebugTextFieldAlertAction(
            title: "Redeem Code",
            alert: DebugTextFieldAlert (
                title: "Enter Code",
                action: { code in
                    guard let code = code, !code.isEmpty else { return }
                    //Simulate Network Call
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        //Show Result Alert
                        self?.debugAlert = DebugAlert(title: "Invalid Code", message: "\(code) is invalid!")
                    }
                }
            )
        )

        let testNumericAlert = DebugTextFieldAlertAction(
            title: "Test Numeric Alert",
            alert: DebugTextFieldAlert (
                title: "Enter Amount",
                keyboardType: .decimalPad,
                action: { _ in }
            )
        )

        //Present UIViewControllers from DebugMenu!
        let hostAction = DebugHostControllerAction(title: "Switch Endpoint") { host in
            let alert = UIAlertController(title: "test", message: "message",preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            host.present(alert, animated: true)
        }

        let debugForceFooAction = DebugToggleAction(title: $debugForceFoo.displayTitle, toggle: Binding(get: { self.debugForceFoo }, set: { self.debugForceFoo = $0 }))
        let showFoosAction = DebugToggleAction(title: $showAllFoos.displayTitle, toggle: Binding(get: { self.showAllFoos }, set: { self.showAllFoos = $0 }))
        let inMemoryAction = DebugToggleAction(title: $inMemoryFlag.displayTitle, toggle: Binding(get: { self.inMemoryFlag }, set: { self.inMemoryFlag = $0 }))
        
        self.addActions([
            testButton,
            testSubmenu,
            testAlert,
            hostAction,
            testNumericAlert,
            debugForceFooAction,
            showFoosAction,
            inMemoryAction
        ])
    }
    
    public override var includeCommonOptions: Bool {
        true
    }
}
