//
//  DebugSubmenuAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import SwiftUI

public struct DebugSubmenuAction: DebugAction {
    let title: String
    let dataSource: BaseDebugDataSource

    public var asAnyView: AnyView {
        AnyView(DebugSubmenuButtonRow(action: self))
    }

    public init(title: String, dataSource: BaseDebugDataSource) {
        self.title = title
        self.dataSource = dataSource
    }
}
