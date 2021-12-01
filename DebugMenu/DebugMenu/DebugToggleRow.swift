//
//  DebugToggleRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

public struct DebugToggleAction {
    let displayTitle: String
    let key: String
    let onToggleComplete: ((Bool) -> Void)?
    let userDefaults: UserDefaults

    public init(title: String, userDefaultsKey: String, onToggleComplete: ((Bool) -> Void)? = nil, userDefaults: UserDefaults = .standard) {
        self.displayTitle = title
        self.key = userDefaultsKey
        self.onToggleComplete = onToggleComplete
        self.userDefaults = userDefaults
    }
}

public struct DebugToggleRow: View {
    let action: DebugToggleAction

    public var body: some View {
        Toggle(action.displayTitle, isOn: binding(for: action.key, onToggleComplete: action.onToggleComplete))
    }

    func binding(for key: String, onToggleComplete: ((Bool) -> Void)? = nil) -> Binding<Bool> {
        Binding { action.userDefaults.bool(forKey: key) } set: { value in
            action.userDefaults.set(value, forKey: key)
            onToggleComplete?(value)
        }
    }
}
