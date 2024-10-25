//
//  DebugPasswordEntry.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-12-06.
//

import SwiftUI
import CommonCrypto

struct DebugPasswordEntry: ViewModifier {

    private let longPressDuration: CGFloat
    private let passwordHash: String
    @State private var showDialog = false
    @Binding var isVisible: Bool
    @Binding var forceShow: Bool

    init(config: DebugMenuAccessConfig,
         isVisible: Binding<Bool>,
         forceShow: Binding<Bool>) {
        self.passwordHash = config.passwordSHA256
        self.longPressDuration = config.longPressDuration
        self._isVisible = isVisible
        self._forceShow = forceShow
    }

    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: longPressDuration) {
                if forceShow == true {
                    isVisible = true
                } else {
                    showDialog = true
                }
            }
            .background {
                Color.clear
                    .debugTextFieldAlert(
                        isPresented: $showDialog,
                        DebugTextFieldAlert(
                            title: "Debug Settings",
                            message: "Enter Password",
                            action: self.onPasswordEntered
                        )
                    )
            }
    }

    private func onPasswordEntered(input: String?) {
        guard let input = input else { return }
        if input.sha256 == self.passwordHash {
            showDialog = false
            isVisible = true
            forceShow = true
        } else {
            showDialog = false
        }
    }
}

public extension View {
    func debugMenuToggle(
        config: DebugMenuAccessConfig,
        isVisible: Binding<Bool>,
        forceShow: Binding<Bool>
    ) -> some View {
        modifier(DebugPasswordEntry(
            config: config,
            isVisible: isVisible,
            forceShow: forceShow
        ))
    }
}

private extension Data {

    var sha256: String {
        hexStringFromData(input: digest(input: self as NSData))
    }

    private func digest(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString
    }
}

private extension String {
    var sha256: String {
        self.data(using: String.Encoding.utf8)?.sha256 ?? ""
    }
}

extension View {
    func debugTextFieldAlert(isPresented: Binding<Bool>, _ alert: DebugTextFieldAlert) -> some View {
        DebugTextFieldAlertWrapper(isPresented: isPresented, alert: alert, content: self)
    }

    func debugAlert(isPresented: Binding<Bool>, _ action: @escaping (UIHostingController<AnyView>) -> Void) -> some View {
        DebugHostControllerWrapper(isPresented: isPresented, action: action, content: AnyView(self))
    }
}
