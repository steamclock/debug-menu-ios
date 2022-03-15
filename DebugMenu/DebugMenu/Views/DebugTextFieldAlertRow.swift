//
//  DebugTextFieldAlertRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import SwiftUI

struct DebugTextFieldAlertRow: View {
    let action: DebugTextFieldAlertAction
    @State var isPresented: Bool = false

    var body: some View {
        HStack {
            Button(action.title, action: { isPresented.toggle() })
                .foregroundColor(.blue)
            Spacer()
        }
        .debugTextFieldAlert(isPresented: $isPresented, action.alert)
    }
}
