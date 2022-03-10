//
//  ContentView.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import DebugMenu

struct ContentView: View {

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
                        dataSource: debugMenu,
                        config: debugMenu.config,
                        isVisible: $debugMenu.isVisible,
                        forceShow: $debugMenu.forceShow
                    )
            }
            Spacer()
        }

        //TODO:
        //Global Config for Debug Password Entry
        //A Generic Alert System SWIFTUI
        //Switchcraft port
        //
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
