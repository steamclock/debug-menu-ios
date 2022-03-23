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
        if !dataSource.sections.isEmpty {
            List {
                ForEach(dataSource.sections) { section in
                    let options = section.actions.map({ $0.asAnyView })
                    Section(header: Text(section.title)) {
                        ForEach(0..<options.count) { index in
                            options[index]
                        }
                    }
                }

                if dataSource.includeCommonOptions {
                    commonOptions()
                }
            }
            .navigationBarTitle(Text(dataSource.navigationTitle), displayMode: .inline)
            .alert(item: $dataSource.debugAlert, content: { alert in
                Alert(
                    title: Text(alert.title),
                    message: (alert.message != nil) ? Text(alert.message ?? "") : nil,
                    primaryButton: .default(Text(alert.primaryButtonTitle)),
                    secondaryButton: .destructive(Text(alert.secondaryButtonTitle), action: {
                        alert.action?()
                    })
                )
            })
        } else {
            Text("No debug options set!")
                .font(.system(size: 20, weight: .semibold))
                .navigationBarTitle(Text(dataSource.navigationTitle), displayMode: .inline)
        }
    }

    @ViewBuilder
    func commonOptions() -> some View {
        Section(header: Text("Common")) {
            DebugButtonAction(title: "Reset To Default Values", action: {
                dataSource.resetToDefaults()
            }).asAnyView
        }
    }
}
