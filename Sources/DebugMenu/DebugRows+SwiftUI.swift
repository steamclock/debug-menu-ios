#if canImport(SwiftUI)
import SwiftUI

/// A row that shows your own SwiftUI view.
public struct DebugCustom: DebugRow {
    /// The row's built definition.
    public var item: DebugItem

    /// Creates a custom row. `title` names the row in its ID and in snapshots, where the view can't be shown.
    /// `value` is optional text that stands in for the view in snapshots.
    public init<Content: View>(
        _ title: String,
        value: @autoclosure @escaping @MainActor @Sendable () -> String? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> Content
    ) {
        let configuration = DebugCustomConfiguration(text: value, makeView: { AnyView(content()) })
        item = DebugItem(id: title, title: title, kind: .custom(configuration))
    }
}

public extension DebugToggle {
    /// Creates a toggle backed by a `Binding`.
    init(_ title: String, isOn: Binding<Bool>) {
        self.init(title, get: { isOn.wrappedValue }, set: { isOn.wrappedValue = $0 })
    }
}

public extension DebugPicker {
    /// Creates a picker over every case of a `DebugPickerValue`, backed by a `Binding`.
    init<Value: DebugPickerValue>(_ title: String, selection: Binding<Value>) {
        self.init(title, get: { selection.wrappedValue }, set: { selection.wrappedValue = $0 })
    }

    /// Creates a picker over an explicit list of options, backed by a `Binding`.
    init<Value: Hashable & Sendable>(
        _ title: String,
        options: [Value],
        optionTitle: @escaping @Sendable (Value) -> String,
        selection: Binding<Value>
    ) {
        self.init(
            title,
            options: options,
            optionTitle: optionTitle,
            get: { selection.wrappedValue },
            set: { selection.wrappedValue = $0 }
        )
    }
}
#endif
