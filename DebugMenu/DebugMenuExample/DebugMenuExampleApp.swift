//
//  DebugMenuExampleApp.swift
//  DebugMenuExample
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import DebugMenu
import switchcraft

@main
struct DebugMenuExampleApp: App {

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

extension Switchcraft {
    static let shared = Switchcraft(config: buildSwitchcraftConfig())
}

func buildSwitchcraftConfig() -> Config {
    .init(
        defaultsKey: "testServerEndpoint",
        endpoints: [
            Endpoint(title: "Production", url: URL(string: "https://prod.server.com")!),
            Endpoint(title: "Testing", url: URL(string: "https://test.server.com")!),
            Endpoint(title: "Development", url: URL(string: "https://dev.server.com")!)
        ],
        allowCustom: true
    )
}
