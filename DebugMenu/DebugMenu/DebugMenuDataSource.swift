//
//  DebugMenuDataSource.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import Foundation

public protocol DebugMenuDataSource: ObservableObject {
    var navigationTitle: String { get }
    var actions: [DebugAction] { get }
    func addAction(_ action: DebugAction)
    func addActions(_ actions: [DebugAction])
}
