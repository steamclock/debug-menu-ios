//
//  DebugSubmenuButtonRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

public struct DebugSubmenuAction: DebugAction {
    let title: String
    let dataSource: BaseDebugDataSource

    public var asAnyView: AnyView {
        AnyView(DebugSubmenuButtonRow(action: self))
    }

    public init(title: String, dataSource: BaseDebugDataSource) {
        self.title = title
        self.dataSource = dataSource
    }
}

struct DebugSubmenuButtonRow: View {
    let action: DebugSubmenuAction
    @State var isPresenting = false

    var body: some View {
        NavigationLink(destination: DebugMenuView(dataSource: action.dataSource),
                       isActive: $isPresenting) {
            Button(action.title, action: { isPresenting = true })
            .foregroundColor(.black)
        }
    }
}
