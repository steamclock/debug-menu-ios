//
//  DebugMenuDataSource.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import Foundation

public enum DebugActionType {
    case toggle(action: DebugToggleAction)
    case button(title: String, action: () -> Void)
    case submenu(action: DebugSubmenuAction)
}

public protocol DebugMenuDataSource: AnyObject {
    var navigationTitle: String { get }
    var actions: [DebugActionType] { get }
    func addAction(_ action: DebugActionType)
}
