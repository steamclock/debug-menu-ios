//
//  DebugSubmenuButtonRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

public struct DebugSubmenuAction {
    let title: String
    let dataSource: Binding<DebugMenuDataSource>

    public init(title: String, dataSource: Binding<DebugMenuDataSource>) {
        self.title = title
        self.dataSource = dataSource
    }
}

struct DebugSubmenuButtonRow: View {
    let action: DebugSubmenuAction
    @State var isPresenting = false

    var body: some View {
        NavigationLink(destination: DebugMenuView(dataSource: action.dataSource.wrappedValue),
                       isActive: $isPresenting) {
            Button(action.title, action: { isPresenting = true })
            .foregroundColor(.black)
        }
    }
}
