//
//  DebugTextFieldAlertAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import Foundation

public struct DebugTextFieldAlertAction: DebugAction {
    let title: String
    let alert: DebugTextFieldAlert

    public init(title: String, alert: DebugTextFieldAlert) {
        self.title = title
        self.alert = alert
    }
}
