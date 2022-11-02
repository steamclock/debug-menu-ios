//
//  DebugSubmenuAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

public struct DebugSubmenuAction: DebugAction {
    let title: String
    let dataSource: BaseDebugDataSource

    public init(title: String, dataSource: BaseDebugDataSource) {
        self.title = title
        self.dataSource = dataSource
    }
}
