//
//  SwiftUIView.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import Combine

public struct DebugMenuView: View {

    private var dataSource: DebugMenuDataSource

    public init(dataSource: DebugMenuDataSource = DebugMenuStore.shared) {
        self.dataSource = dataSource
    }

    public var body: some View {
        let options = dataSource.actions.map({ actionTypeToAnyView($0) })
        NavigationView {
            if !options.isEmpty {
                List {
                    ForEach(0..<options.count) { index in
                        options[index]
                    }
                }
                .navigationBarTitle(Text(dataSource.navigationTitle), displayMode: .inline)
            } else {
                Text("No debug options set!")
                    .font(.system(size: 20, weight: .semibold))
                    .navigationBarTitle(Text(dataSource.navigationTitle), displayMode: .inline)
            }
        }
    }

    func actionTypeToAnyView(_ type: DebugActionType) -> AnyView {
        switch type {
        case .toggle(let action):
            return AnyView(DebugToggleRow(action: action))
        case .button(let title, let action):
            return AnyView(DebugButtonRow(title: title, action: action))
        case .submenu(let action):
            return AnyView(DebugSubmenuButtonRow(action: action))
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenuView()
    }
}
