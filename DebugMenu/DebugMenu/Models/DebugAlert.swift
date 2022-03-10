//
//  DebugAlert.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import Foundation

public struct DebugAlert: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String?
    public let primaryButtonTitle: String
    public let secondaryButtonTitle: String
    public let action: (() -> Void)?

    public init(
        title: String,
        message: String? = nil,
        primaryButtonTitle: String = "OK",
        secondaryButtonTitle: String = "Cancel",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.action = action
    }
}
