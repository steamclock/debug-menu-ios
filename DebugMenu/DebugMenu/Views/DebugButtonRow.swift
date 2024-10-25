//
//  DebugButtonRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

struct DebugButtonRow: View {
    @State var showConfirmation: Bool = false
    let action: DebugButtonAction

    var body: some View {
        if let confirmationMessage = action.confirmationMessage {
            Button(action.title) {
                showConfirmation = true
            }
            .alert("", isPresented: $showConfirmation) {
                Button("Ok", role: .destructive) {
                    action.action()
                }
            } message: {
                Text(confirmationMessage)
            }
        } else {
            Button(action.title, action: action.action)
                .foregroundColor(.blue)
        }
    }
}
