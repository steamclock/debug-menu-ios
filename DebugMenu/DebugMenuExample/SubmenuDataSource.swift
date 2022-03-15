//
//  SubmenuDataSource.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import DebugMenu

public class SubmenuDataSource: BaseDebugDataSource {

    public override var navigationTitle: String {
        "Submenu"
    }

    init() {
        super.init(actions: [DebugButtonAction(title: "Submenu option", action: { })])
    }
}

