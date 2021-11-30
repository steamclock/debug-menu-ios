//
//  SwiftUIView.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

public struct DebugToggleAction {
    let displayTitle: String
    let key: String
    let onToggleComplete: ((Bool) -> Void)?

    public init(title: String, userDefaultsKey: String, onToggleComplete: ((Bool) -> Void)?) {
        self.displayTitle = title
        self.key = userDefaultsKey
        self.onToggleComplete = onToggleComplete
    }
}

public struct DebugToggleRow: View {
    let action: DebugToggleAction
    let defaults = UserDefaults.standard

    public var body: some View {
        Toggle(action.displayTitle, isOn: binding(for: action.key, onToggleComplete: action.onToggleComplete))
    }

    func binding(for key: String, onToggleComplete: ((Bool) -> Void)? = nil) -> Binding<Bool> {
        Binding { defaults.bool(forKey: key) } set: { value in
            defaults.set(value, forKey: key)
            onToggleComplete?(value)
        }
    }
}
