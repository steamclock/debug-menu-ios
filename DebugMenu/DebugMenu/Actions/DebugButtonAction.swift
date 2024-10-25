//
//  DebugButtonAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

public struct DebugButtonAction: DebugAction {
    let title: String
    let confirmationMessage: String?
    let action: () -> Void
    
    public init(title: String, confirmationMessage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.confirmationMessage = confirmationMessage
        self.action = action
    }
}
