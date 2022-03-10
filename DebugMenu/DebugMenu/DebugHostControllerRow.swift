//
//  DebugHostControllerRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import SwiftUI

public struct DebugHostControllerAction: DebugAction {
    let title: String
    let action: (UIHostingController<AnyView>) -> Void

    public var asAnyView: AnyView {
        AnyView(DebugHostControllerRow(action: self))
    }

    public init(title: String, action: @escaping (UIHostingController<AnyView>) -> Void) {
        self.title = title
        self.action = action
    }
}

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
