//
//  DebugToggle.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-12-02.
//

import SwiftUI
import Combine

@propertyWrapper
public struct DebugToggle<Value> {

    public let displayTitle: String
    public let defaultValue: Value
    public let storage: UserDefaults
    public let key: String?

    private var value: Value

    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError("only works on instance properties of classes") }
        set { fatalError("only works on instance properties of classes") }
    }

    public var projectedValue: Self {
        self
    }

    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            let propertyWrapper = object[keyPath: storageKeyPath]
            if let key = propertyWrapper.key {
                return propertyWrapper.storage.object(forKey: key) as? Value ?? propertyWrapper.defaultValue
            } else {
                return propertyWrapper.value
            }
        }
        set {
            (object.objectWillChange as? ObservableObjectPublisher)?.send()
            let propertyWrapper = object[keyPath: storageKeyPath]
            if let key = propertyWrapper.key {
                if let optional = newValue as? AnyOptional, optional.isNil {
                    propertyWrapper.storage.removeObject(forKey: key)
                } else {
                    propertyWrapper.storage.set(newValue, forKey: key)
                }
            } else {
                object[keyPath: storageKeyPath].value = newValue
            }
        }
    }

    public init(wrappedValue: Value,
                key: String,
                storage: UserDefaults = .standard) {
        self.displayTitle = key.camelCaseToWords().replacingOccurrences(of: "Key", with: "")
        self.defaultValue = wrappedValue
        self.key = key
        self.storage = storage
        self.value = wrappedValue
    }

    public init(wrappedValue: Value,
                title: String,
                key: String? = nil,
                storage: UserDefaults = .standard) {
        self.displayTitle = title
        self.defaultValue = wrappedValue
        self.storage = storage
        self.key = key
        self.value = wrappedValue
    }
}

public extension DebugToggle where Value: ExpressibleByNilLiteral {
    init(title: String) {
        self.init(wrappedValue: nil, title: title)
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

private extension String {
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
