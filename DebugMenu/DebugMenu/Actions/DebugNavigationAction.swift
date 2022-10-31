//
//  DebugNavigationAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-10-31.
//

import SwiftUI

public struct DebugNavigationAction<Destination: View>: DebugCustomAction {
    let title: String
    let destination: Destination

    public var rowView: AnyView {
        AnyView(DebugNavigationRow(action: self))
    }

    public init(title: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.destination = destination()
    }
}
