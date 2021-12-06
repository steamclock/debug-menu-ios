//
//  DebugMenuView.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import Combine

public struct DebugMenuView: View {

    private var dataSource: DebugMenuDataSource

    public init(dataSource: DebugMenuDataSource) {
        self.dataSource = dataSource
    }

    public var body: some View {
        let options = dataSource.actions.map({ $0.asAnyView })
        NavigationView {
            if !options.isEmpty {
                List {
                    ForEach(0..<options.count) { index in
                        options[index]
                    }
                }
                .navigationBarTitle(Text(dataSource.navigationTitle), displayMode: .inline)
            } else {
                Text("No debug options set!")
                    .font(.system(size: 20, weight: .semibold))
                    .navigationBarTitle(Text(dataSource.navigationTitle), displayMode: .inline)
            }
        }
    }
}
