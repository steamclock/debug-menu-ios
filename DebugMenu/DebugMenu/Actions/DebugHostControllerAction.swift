//
//  DebugHostControllerAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import SwiftUI

public struct DebugHostControllerAction: DebugAction {
    let title: String
    let action: (UIHostingController<AnyView>) -> Void

    public init(title: String, action: @escaping (UIHostingController<AnyView>) -> Void) {
        self.title = title
        self.action = action
    }
}
