//
//  DebugButtonAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import Foundation

public struct DebugButtonAction: DebugAction {
    let title: String
    let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}
