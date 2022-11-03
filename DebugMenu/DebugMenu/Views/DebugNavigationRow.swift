//
//  File.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-10-31.
//

import SwiftUI

struct DebugNavigationRow<Destination: View>: View {

    let action: DebugNavigationAction<Destination>

    var body: some View {
        NavigationLink {
            action.destination
        } label: {
            Text(action.title)
        }
    }
}
