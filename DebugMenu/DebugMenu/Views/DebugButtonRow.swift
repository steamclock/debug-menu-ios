//
//  DebugButtonRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

struct DebugButtonRow: View {
    let action: DebugButtonAction

    var body: some View {
        Button(action.title, action: action.action)
            .foregroundColor(.blue)
    }
}
