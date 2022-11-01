//
//  MainView.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import DebugMenu

struct MainView: View {

    @ObservedObject var debugMenu = DebugMenuStore.shared

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                if debugMenu.isVisible {
                    NavigationLink("To Debug Menu!") {
                        DebugMenuView(dataSource: DebugMenuStore.shared)
                    }
                }
                Text("Debug Hidden Entry")
                    .debugMenuToggle(
                        config: debugMenu.config,
                        isVisible: $debugMenu.isVisible,
                        forceShow: $debugMenu.forceShow
                    )
            }
            Spacer()
        }
    }
}
