//
//  DebugTextFieldAlertRow.swift
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
