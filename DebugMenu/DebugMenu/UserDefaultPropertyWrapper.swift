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
    public let displayTitle: String
    public let defaultValue: Value
    var storage: UserDefaults
    public var onValueSet: ((Value) -> Void)? = nil

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
            onValueSet?(newValue)
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    public init(wrappedValue defaultValue: Value,
                title: String? = nil,
                key: String,
                storage: UserDefaults = .standard) {
        self.key = key
        self.displayTitle = title ?? key.camelCaseToWords().replacingOccurrences(of: "Key", with: "")
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

fileprivate extension String {

    func camelCaseToWords() -> String {

        return unicodeScalars.reduce("") {

            if CharacterSet.uppercaseLetters.contains($1) {

                return ($0.capitalized + " " + String($1))
            }
            else {

                return $0.capitalized + String($1)
            }
        }
    }
}
