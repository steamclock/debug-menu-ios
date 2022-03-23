//
//  DebugSection.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-23.
//

import Foundation

public struct DebugSection: Identifiable {
    public let id = UUID()
    public let title: String
    public private(set) var actions: [DebugAction]

    public init(title: String, actions: [DebugAction]) {
        self.title = title
        self.actions = actions
    }

    public mutating func addActions(_ actions: [DebugAction]) {
        self.actions.append(contentsOf: actions)
    }
}
