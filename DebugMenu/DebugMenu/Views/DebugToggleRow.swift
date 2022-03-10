//
//  DebugToggleRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI
import Combine

struct DebugToggleRow: View {
    let action: DebugToggleAction

    var body: some View {
        Toggle(action.displayTitle, isOn: action.toggle)
    }
}
