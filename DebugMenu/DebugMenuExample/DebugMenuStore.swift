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
import switchcraft

public class DebugMenuStore: BaseDebugDataSource {
    
    @DebugToggle(key: "debugForceFooKey", didSet: debugForceFooSet) var debugForceFoo = false
    @DebugToggle(title: "Show All Foos", key: "showFoosKey") var showAllFoos = false
    @DebugToggle(title: "In Memory Flag") var inMemoryFlag = false

    @Published public var forceShow = false
    @Published public var isVisible = false

    public static let shared = DebugMenuStore()

    let config = DebugMenuAccessConfig(passwordSHA256: "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", longPressDuration: 2.0)
    
    init() {
        super.init()
        self.addSections([toggleSection, buttonSection, alertSection])
    }

    // Trigger additional functionality on toggle
    private static func debugForceFooSet(value: Bool) {
        print("DebugForceFoo set to \(value)")
    }

    lazy var toggleSection: DebugSection = {
        DebugSection(title: "Toggles", actions: [$debugForceFoo.action, $showAllFoos.action, $inMemoryFlag.action])
    }()

    lazy var buttonSection: DebugSection = {
        let testButton = DebugButtonAction(title: "Test Button", action: { print("Button Tapped") })
        let testSubmenu = DebugSubmenuAction(title: "Test submenu", dataSource: SubmenuDataSource())

        return DebugSection(title: "Buttons", actions: [testButton, testSubmenu])
    }()

    lazy var alertSection: DebugSection = {

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
            Switchcraft.shared.display(from: host)
        }

        let navigateAction = DebugNavigationAction(title: "SwiftUI View") {
            Text("Hi")
        }

        return DebugSection(title: "Alerts", actions: [testAlert, testNumericAlert, hostAction, navigateAction])
    }()

    lazy var testAlert: DebugTextFieldAlertAction = {
        DebugTextFieldAlertAction(
            title: "Redeem Code",
            alert: DebugTextFieldAlert (
                title: "Enter Code",
                action: { code in
                    guard let code = code, !code.isEmpty else { return }
                    //Simulate Network Call
                    self.isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        //Show Result Alert
                        self?.isLoading = false
                        self?.debugAlert = DebugAlert(title: "Invalid Code", message: "\(code) is invalid!")
                    }
                }
            )
        )
    }()

    public override var includeCommonOptions: Bool {
        true
    }
}
