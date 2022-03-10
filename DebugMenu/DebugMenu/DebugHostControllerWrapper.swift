//
//  DebugHostControllerWrapper.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

import UIKit
import SwiftUI

struct DebugHostControllerWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let action: (UIHostingController<Content>) -> Void
    let content: Content

    func makeUIViewController(context: UIViewControllerRepresentableContext<DebugHostControllerWrapper>) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }

    final class Coordinator { }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: UIViewControllerRepresentableContext<DebugHostControllerWrapper>) {
        uiViewController.rootView = content
        if isPresented && uiViewController.presentedViewController == nil {
            action(uiViewController)
        }
    }
}
