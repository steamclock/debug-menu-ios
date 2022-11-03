//
//  DebugToggleRow.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI
import Combine

struct DebugToggleRow<DataSource>: View where DataSource: DebugMenuDataSource  {

    let action: DebugToggleAction
    @EnvironmentObject var dataSource: DataSource
    @Binding var toggle: Bool

    // This state is required to force redraw when resetting toggle to default value
    @State var redraw: Bool = false

    var body: some View {
        Toggle(action.displayTitle, isOn: $toggle)
            .onReceive(action.publisher) { _ in
                redraw.toggle()
            }
    }
}
