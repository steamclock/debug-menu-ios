//
//  DebugHostControllerRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import SwiftUI

public struct DebugHostControllerRow: View {
    let action: DebugHostControllerAction
    @State var isPresented: Bool = false

    public var body: some View {
        HStack {
            Button(action.title, action: { isPresented.toggle() })
                .foregroundColor(.blue)
            Spacer()
        }
        .debugAlert(isPresented: $isPresented, action.action)
    }
}
