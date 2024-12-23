//
//  DebugToggle.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-12-02.
//

import SwiftUI
import Combine

@propertyWrapper
public struct DebugToggle: DynamicProperty  {

    public let displayTitle: String
    public let defaultValue: Bool
    public var publisher: PassthroughSubject<Bool, Never>
    public let didSet: ((Bool) -> Void)?
    public let willSet: (Bool) async -> Bool

    @ObservedObject public private(set) var storage: Storage

    public var wrappedValue: Bool {
        get {
            storage.value
        }
        nonmutating set {
            Task {
                if await willSet(newValue) {
                    storage.value = newValue
                    didSet?(newValue)
                    publisher.send(newValue)
                }
            }
        }
    }

    public var projectedValue: Self {
        self
    }

    public var action: DebugToggleAction {
        DebugToggleAction(title: displayTitle, toggle: binding, defaultValue: defaultValue, publisher: publisher)
    }

    public var binding: Binding<Bool> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    public init(
        wrappedValue defaultValue: Bool,
        title: String? = nil,
        key: String,
        storage: UserDefaults = .standard,
        didSet: ((Bool) -> Void)? = nil,
        willSet: @escaping (Bool) async -> Bool = { _ in true }
    ) {
        self.defaultValue = defaultValue
        self.displayTitle = title ?? key.camelCaseToWords().replacingOccurrences(of: "Key", with: "").trimmingCharacters(in: .whitespaces)
        self.publisher = PassthroughSubject<Bool, Never>()
        self.storage = Storage(defaultValue, key: key, storage: storage)
        self.didSet = didSet
        self.willSet = willSet
    }

    public init(
        wrappedValue defaultValue: Bool,
        title: String,
        didSet: ((Bool) -> Void)? = nil,
        willSet: @escaping (Bool) async -> Bool = { _ in true }
    ) {
        self.defaultValue = defaultValue
        self.displayTitle = title
        self.publisher = PassthroughSubject<Bool, Never>()
        self.storage = Storage(defaultValue)
        self.didSet = didSet
        self.willSet = willSet
    }

    final public class Storage: NSObject, ObservableObject {
        let key: String?
        var storedValue: Bool
        var store: UserDefaults

        var value: Bool {
            get {
                if let key = key {
                    return store.value(forKey: key) as? Bool ?? storedValue
                } else {
                    return storedValue
                }
            }
            set {
                objectWillChange.send()
                if let key = key {
                    if let optional = newValue as? AnyOptional, optional.isNil {
                        store.removeObject(forKey: key)
                    } else {
                        store.setValue(newValue, forKey: key)
                    }
                } else {
                    storedValue = newValue
                }
            }
        }

        init(_ value: Bool) {
            self.storedValue = value
            self.store = UserDefaults.standard
            self.key = nil
            super.init()
        }

        init(_ value: Bool, key: String, storage: UserDefaults) {
            self.storedValue = value
            self.store = storage
            self.key = key
            super.init()
            store.addObserver(self, forKeyPath: key, options: [.new], context: nil)
        }

        deinit {
            store.removeObserver(self, forKeyPath: key ?? "")
        }

        public override func observeValue(forKeyPath keyPath: String?,
                                          of object: Any?,
                                          change: [NSKeyValueChangeKey : Any]?,
                                          context: UnsafeMutableRawPointer?) {

            value = change?[.newKey] as? Bool ?? storedValue
        }
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
