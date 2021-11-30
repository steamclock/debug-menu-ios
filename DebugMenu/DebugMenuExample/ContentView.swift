//
//  ContentView.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import DebugMenu

struct ContentView: View {

    @State var showDebugMenu = false

    var body: some View {
        Button("Debug Menu Entry Point") {
            showDebugMenu = true
        }
        .sheet(isPresented: $showDebugMenu) {
            DebugMenuView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
