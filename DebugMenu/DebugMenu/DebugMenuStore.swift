import Combine
import Foundation

public struct DebugSubmenuAction {
    let title: String
    let dataSource: DebugMenuDataSource
}

public enum DebugActionType {
    case toggle(action: DebugToggleAction)
    case button(title: String, action: () -> Void)
    case submenu(action: DebugSubmenuAction)
}

public protocol DebugMenuDataSource {
    var actions: [DebugActionType] { get }
    func addActions(_ actions: [DebugActionType])
}

public class DebugMenuStore: ObservableObject, DebugMenuDataSource {

    public static let shared = DebugMenuStore()

    @Published private var debugActions: [DebugActionType]

    public var actions: [DebugActionType] {
        return debugActions
    }

    public init() {
        debugActions = []
    }

    public func addActions(_ actions: [DebugActionType]) {
        debugActions.append(contentsOf: actions)
    }
}
