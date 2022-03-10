//
//  DebugTextFieldAlert.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import Foundation
import UIKit

public struct DebugTextFieldAlert {

    var title: String
    var message: String?
    var placeholder: String?
    var accept: String
    var cancel: String?
    var secondaryActionTitle: String?
    var keyboardType: UIKeyboardType
    var action: (String?) -> Void
    var secondaryAction: (() -> Void)?

    public init(title: String,
         message: String? = nil,
         placeholder: String? = nil,
         accept: String = "OK",
         cancel: String? = "Cancel",
         secondaryActionTitle: String? = nil,
         keyboardType: UIKeyboardType = .default,
         action: @escaping (String?) -> Void,
         secondaryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.placeholder = placeholder
        self.accept = accept
        self.cancel = cancel
        self.secondaryActionTitle = secondaryActionTitle
        self.keyboardType = keyboardType
        self.action = action
        self.secondaryAction = secondaryAction
    }
}
