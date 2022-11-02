//
//  DebugMenuAccessConfig.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-03-10.
//

public struct DebugMenuAccessConfig {
    public var passwordSHA256: String
    public var longPressDuration: Double

    public init(passwordSHA256: String, longPressDuration: Double) {
        self.passwordSHA256 = passwordSHA256
        self.longPressDuration = longPressDuration
    }
}
