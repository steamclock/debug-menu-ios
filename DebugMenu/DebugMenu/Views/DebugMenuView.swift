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
        if !dataSource.sections.flatMap({ $0.actions }).isEmpty {
            List {
                ForEach(dataSource.sections) { section in
                    Section(header: Text(section.title)) {
                        ForEach(0..<section.actions.count, id: \.self) { index in
                            viewForAction(section.actions[index])
                        }
                    }
                }

                if dataSource.includeCommonOptions {
                    commonOptions()
                }
            }
            .environmentObject(dataSource)
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

    @ViewBuilder func viewForAction(_ action: DebugAction) -> some View {
        if let action = action as? DebugToggleAction {
            DebugToggleRow<DataSource>(action: action, toggle: action.$toggle)
        } else if let action = action as? DebugButtonAction {
            DebugButtonRow(action: action)
        } else if let action = action as? DebugSubmenuAction {
            DebugSubmenuButtonRow(action: action)
        } else if let action = action as? DebugHostControllerAction {
            DebugHostControllerRow(action: action)
        } else if let action = action as? DebugTextFieldAlertAction {
            DebugTextFieldAlertRow(action: action)
        } else  {
            Text("Unsupported Action")
        }
    }

    @ViewBuilder
    func commonOptions() -> some View {
        Section(header: Text("Common")) {
            let action = DebugButtonAction(title: "Reset To Default Values", action: {
                dataSource.resetToDefaults()
            })
            DebugButtonRow(action: action)
        }
    }
}
