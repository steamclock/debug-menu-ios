//
//  File.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-12-06.
//

import Foundation
import UIKit
import SwiftUI

internal struct DebugPasswordAlert {

    public var title: String
    public var message: String
    public var placeholder: String
    public var accept: String
    public var cancel: String?
    public var secondaryActionTitle: String?
    public var keyboardType: UIKeyboardType
    public var action: (String?) -> Void
    public var secondaryAction: (() -> Void)?

    public init(title: String = "Debug Settings",
                message: String = "Enter Password",
                placeholder: String = "",
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

internal extension UIAlertController {
    convenience init(alert: DebugPasswordAlert) {
        self.init(title: alert.title, message: alert.message, preferredStyle: .alert)
        addTextField {
            $0.placeholder = alert.placeholder
            $0.keyboardType = alert.keyboardType
        }
        if let cancel = alert.cancel {
            addAction(UIAlertAction(title: cancel, style: .cancel) { _ in
                alert.action(nil)
            })
        }
        if let secondaryActionTitle = alert.secondaryActionTitle {
            addAction(UIAlertAction(title: secondaryActionTitle, style: .default, handler: { _ in
                alert.secondaryAction?()
            }))
        }
        let textField = self.textFields?.first
        addAction(UIAlertAction(title: alert.accept, style: .default) { _ in
            alert.action(textField?.text)
        })
    }
}

internal struct DebugPasswordAlertWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding public var isPresented: Bool
    public let alert: DebugPasswordAlert
    public let content: Content

    public func makeUIViewController(context: UIViewControllerRepresentableContext<DebugPasswordAlertWrapper>) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }

    public final class Coordinator {
        var alertController: UIAlertController?
        init(_ controller: UIAlertController? = nil) {
            self.alertController = controller
        }
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    public func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: UIViewControllerRepresentableContext<DebugPasswordAlertWrapper>) {
        uiViewController.rootView = content
        if isPresented && uiViewController.presentedViewController == nil {
            var alert = self.alert
            alert.action = {
                self.isPresented = false
                self.alert.action($0)
            }
            context.coordinator.alertController = UIAlertController(alert: alert)
            uiViewController.present(context.coordinator.alertController!, animated: true)
        }
        if !isPresented && uiViewController.presentedViewController == context.coordinator.alertController {
            uiViewController.dismiss(animated: true)
        }
    }
}