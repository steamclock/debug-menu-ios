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
        if !options.isEmpty {
            List {
                ForEach(0..<options.count) { index in
                    options[index]
                }
            }
        } else {
            Text("No debug options set!")
                .font(.system(size: 20, weight: .semibold))
        }
    }

    func actionTypeToAnyView(_ type: DebugActionType) -> AnyView {
        switch type {
        case .toggle(let action):
            return AnyView(DebugToggleRow(action: action))
        case .button(let title, let action):
            return AnyView(DebugButtonRow(title: title, action: action))
        case .submenu(let action):
            return AnyView(DebugButtonRow(title: action.title, action: {
                print("push to screen")
            }, showChevron: true))
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenuView()
    }
}
