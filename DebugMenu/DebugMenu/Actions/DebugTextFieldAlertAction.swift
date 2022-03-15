//
//  DebugTextFieldAlertAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import SwiftUI

public struct DebugTextFieldAlertAction: DebugAction {
    let title: String
    let alert: DebugTextFieldAlert

    public var asAnyView: AnyView {
        AnyView(DebugTextFieldAlertRow(action: self))
    }

    public init(title: String, alert: DebugTextFieldAlert) {
        self.title = title
        self.alert = alert
    }
}
