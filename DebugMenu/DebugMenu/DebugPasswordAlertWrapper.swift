//
//  File.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-12-06.
//

import Foundation
import UIKit
import SwiftUI

struct DebugPasswordAlertWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let alert: DebugPasswordAlert
    let content: Content

    func makeUIViewController(context: UIViewControllerRepresentableContext<DebugPasswordAlertWrapper>) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }

    final class Coordinator {
        var alertController: UIAlertController?
        init(_ controller: UIAlertController? = nil) {
            self.alertController = controller
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: UIViewControllerRepresentableContext<DebugPasswordAlertWrapper>) {
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

struct DebugPasswordAlert {

    var title: String
    var message: String
    var placeholder: String
    var accept: String
    var cancel: String?
    var secondaryActionTitle: String?
    var keyboardType: UIKeyboardType
    var action: (String?) -> Void
    var secondaryAction: (() -> Void)?

    init(title: String = "Debug Settings",
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

extension UIAlertController {
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

