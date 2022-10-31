//
//  DebugToggleAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import SwiftUI
import Combine

public struct DebugToggleAction: DebugAction, DebugResettable {

    let displayTitle: String
    @Binding var toggle: Bool
    public private(set) var defaultValue: Bool
    public var publisher: PassthroughSubject<Bool, Never>

    public init(title: String, toggle: Binding<Bool>, defaultValue: Bool, publisher: PassthroughSubject<Bool, Never>) {
        self.displayTitle = title
        self._toggle = toggle
        self.defaultValue = defaultValue
        self.publisher = publisher
    }

    public func resetToDefault() {
        $toggle.wrappedValue = defaultValue
    }
}
