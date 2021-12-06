//
//  ContentView.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import DebugMenu

struct ContentView: View {

    var body: some View {
        Text("Debug Hidden Entry")
            .debugEntryPointing(dataSource: DebugMenuStore.shared,
                                passwordSHA256: "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
                                longPressDuration: 2.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
