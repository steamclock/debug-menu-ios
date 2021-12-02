//
//  UserDefaultPropertyWrapper.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-12-02.
//

import SwiftUI

@propertyWrapper
public struct UserDefault<Value> {

    let key: String
    let defaultValue: Value
    var storage: UserDefaults

    public var wrappedValue: Value {
        get {
            storage.value(forKey: key) as? Value ?? defaultValue
        }
        nonmutating set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
            } else {
                storage.setValue(newValue, forKey: key)
            }
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    public init(wrappedValue defaultValue: Value,
         key: String,
         storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }
}

extension UserDefault where Value: ExpressibleByNilLiteral {
    public init(key: String, storage: UserDefaults = .standard) {
        self.init(wrappedValue: nil, key: key, storage: storage)
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
