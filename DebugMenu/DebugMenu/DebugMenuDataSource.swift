//
//  DebugMenuDataSource.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import Foundation

public protocol DebugMenuDataSource: ObservableObject {
    var navigationTitle: String { get }
    var sections: [DebugSection] { get }
    func addSection(_ action: DebugSection)
    func addSections(_ actions: [DebugSection])
    func resetToDefaults()
    var includeCommonOptions: Bool { get }
    var debugAlert: DebugAlert? { get set }
}

extension DebugMenuDataSource {
    public func resetToDefaults() {
        for action in sections.flatMap({ $0.actions }) {
            (action as? DebugResettable)?.resetToDefault()
        }
    }
}
