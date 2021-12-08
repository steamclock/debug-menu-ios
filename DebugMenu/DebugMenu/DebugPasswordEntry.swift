//
//  DebugPasswordEntry.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-12-06.
//

import Foundation
import SwiftUI
import CommonCrypto

internal struct DebugPasswordEntry: ViewModifier {

    private let debugDataSource: DebugMenuDataSource
    private let longPressDuration: CGFloat
    private let passwordHash: String
    @State private var showDialog = false
    @State private var showDebugMenu = false
    private let forceShow: Binding<Bool>?

    public init(dataSource: DebugMenuDataSource,
                passwordSHA256: String,
                longPressDuration: CGFloat,
                forceShow: Binding<Bool>? = nil) {
        self.passwordHash = passwordSHA256
        self.longPressDuration = longPressDuration
        self.debugDataSource = dataSource
        self.forceShow = forceShow
    }

    public func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: longPressDuration) {
                if let forceShow = forceShow?.wrappedValue, forceShow == true {
                    showDebugMenu = true
                } else {
                    showDialog = true
                }
            }
            .debugPasswordAlert(isPresented: $showDialog, DebugPasswordAlert(action: self.onPasswordEntered))
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView(dataSource: debugDataSource)
            }
    }

    private func onPasswordEntered(input: String?) {
        guard let input = input else { return }
        if input.sha256 == self.passwordHash {
            showDialog = false
            showDebugMenu = true
            forceShow?.wrappedValue = true
        } else {
            showDialog = false
        }
    }
}

public extension View {
    func debugMenuNavigation(dataSource: DebugMenuDataSource,
                             passwordSHA256: String,
                             longPressDuration: CGFloat = 5.0,
                             forceShow: Binding<Bool>? = nil) -> some View {
        modifier(DebugPasswordEntry(dataSource: dataSource,
                                    passwordSHA256: passwordSHA256,
                                    longPressDuration: longPressDuration,
                                    forceShow: forceShow))
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

internal extension View {
    func debugPasswordAlert(isPresented: Binding<Bool>, _ alert: DebugPasswordAlert) -> some View {
        DebugPasswordAlertWrapper(isPresented: isPresented, alert: alert, content: self)
    }
}
