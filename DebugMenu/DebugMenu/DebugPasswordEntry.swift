//
//  DebugPasswordEntry.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-12-06.
//

import Foundation
import SwiftUI
import CommonCrypto

public struct DebugPasswordEntry: ViewModifier {

    private let debugDataSource: DebugMenuDataSource
    private let longPressDuration: CGFloat
    private let passwordHash: String
    @State private var showDialog = false
    @State private var showDebugMenu = false

    public init(dataSource: DebugMenuDataSource, passwordSHA256: String, longPressDuration: CGFloat) {
        self.passwordHash = passwordSHA256
        self.longPressDuration = longPressDuration
        self.debugDataSource = dataSource
    }

    public func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: longPressDuration) {
                showDialog = true
            }.alert(isPresented: $showDialog, TextAlert(title: "Debug Settings", message: "Enter Password") { result in
                guard let result = result else { return }
                print(result.sha256() == self.passwordHash)
                if result.sha256() == self.passwordHash {
                    showDialog = false
                    showDebugMenu = true
                } else {
                    showDialog = false
                }
            })
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView(dataSource: debugDataSource)
            }
    }
}

public extension View {
    func debugEntryPointing(dataSource: DebugMenuDataSource, passwordSHA256: String, longPressDuration: CGFloat = 5.0) -> some View {
        modifier(DebugPasswordEntry(dataSource: dataSource, passwordSHA256: passwordSHA256, longPressDuration: longPressDuration))
    }
}

public extension Data {
    func sha256() -> String{
        return hexStringFromData(input: digest(input: self as NSData))
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

public extension String {
    func sha256() -> String{
        if let stringData = self.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }
}

