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
        let actions = [DebugButtonAction(title: "Submenu option", action: { })]
        super.init(sections: [DebugSection(title: "", actions: actions)])
    }
}

