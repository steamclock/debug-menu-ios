//
//  DebugToggleRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI
import Combine

public protocol DebugAction {
    var asAnyView: AnyView { get }
}

public struct DebugToggleAction: DebugAction {

    let displayTitle: String
    let toggle: Binding<Bool>
    let defaultValue: Bool

    public var asAnyView: AnyView {
        AnyView(DebugToggleRow(action: self))
    }

    public init(title: String, toggle: Binding<Bool>) {
        self.displayTitle = title
        self.toggle = toggle
        self.defaultValue = toggle.wrappedValue
    }
}

extension DebugToggleAction: DebugResettable {
    public func resetToDefault() {
        toggle.wrappedValue = defaultValue
    }
}

public struct DebugToggleRow: View {
    let action: DebugToggleAction

    public var body: some View {
        Toggle(action.displayTitle, isOn: action.toggle)
    }
}
