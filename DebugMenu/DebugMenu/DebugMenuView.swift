//
//  DebugMenuView.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-29.
//

import SwiftUI
import Combine

public struct DebugMenuView<DataSource>: View where DataSource: DebugMenuDataSource {

    @ObservedObject private var dataSource: DataSource

    public init(dataSource: DataSource) {
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
