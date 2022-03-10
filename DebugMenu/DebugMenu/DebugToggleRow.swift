//
//  DebugToggleRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI
import Combine

public struct DebugToggleAction: DebugAction, DebugResettable {

    let displayTitle: String
    let toggle: Binding<Bool>
    public private(set) var defaultValue: Bool

    public var asAnyView: AnyView {
        AnyView(DebugToggleRow(action: self))
    }

    public init(title: String, toggle: Binding<Bool>) {
        self.displayTitle = title
        self.toggle = toggle
        self.defaultValue = toggle.wrappedValue
    }

    public func resetToDefault() {
        toggle.wrappedValue = defaultValue
    }
}

struct DebugToggleRow: View {
    let action: DebugToggleAction

    var body: some View {
        Toggle(action.displayTitle, isOn: action.toggle)
    }
}
