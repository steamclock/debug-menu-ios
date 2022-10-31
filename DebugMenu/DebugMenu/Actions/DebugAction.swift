//
//  DebugAction.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import SwiftUI

public protocol DebugAction {}

//For use with Actions that utilize generics where type cannot be inferred at view resolution time &
//For Any consumers that want to define custom actions
public protocol DebugCustomAction: DebugAction {
    var rowView: AnyView { get }
}
