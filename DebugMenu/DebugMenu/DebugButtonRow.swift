//
//  DebugButtonRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

public struct DebugButtonAction: DebugAction {
    let title: String
    let action: () -> Void

    public var asAnyView: AnyView {
        AnyView(DebugButtonRow(action: self))
    }

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}

struct DebugButtonRow: View {
    let action: DebugButtonAction

    var body: some View {
        Button(action.title, action: action.action)
            .foregroundColor(.blue)
    }
}
