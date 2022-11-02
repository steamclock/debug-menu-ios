//
//  DebugResettable.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

public protocol DebugResettable {
    var defaultValue: Bool { get }
    func resetToDefault()
}
