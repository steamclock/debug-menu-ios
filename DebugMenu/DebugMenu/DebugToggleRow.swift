//
//  SwiftUIView.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

public struct UserDefaultsToggleAction {
    let displayTitle: String
    let key: String
    let onToggleComplete: (() -> Void)?
}

public struct DebugToggleRow: View {
    let action: UserDefaultsToggleAction
    let defaults = UserDefaults.standard

    public var body: some View {
        Toggle(action.displayTitle, isOn: binding(for: action.key, onToggleComplete: action.onToggleComplete))
    }

    func binding(for key: String, onToggleComplete: (() -> Void)? = nil) -> Binding<Bool> {
        Binding { defaults.bool(forKey: key) } set: { value in
            defaults.set(value, forKey: key)
        }
    }
}
