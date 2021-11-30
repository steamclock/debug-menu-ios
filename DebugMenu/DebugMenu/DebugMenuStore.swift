import Combine
import Foundation

public class DebugMenuStore: ObservableObject, DebugMenuDataSource {

    public static let shared = DebugMenuStore()

    public var navigationTitle: String {
        "Debug Menu"
    }

    public private(set) var actions: [DebugActionType]

    public init(actions: [DebugActionType] = []) {
        self.actions = actions
    }

    public func addActions(_ actions: [DebugActionType]) {
        self.actions.append(contentsOf: actions)
    }
}
