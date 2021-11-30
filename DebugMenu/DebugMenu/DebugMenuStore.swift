import Combine
import Foundation

public class DebugMenuStore: BaseDebugDataSource {

    public static let shared = DebugMenuStore()

    init() {
        super.init(actions: [])
    }
}

open class BaseDebugDataSource: DebugMenuDataSource {

    open var navigationTitle: String {
        "Debug Menu"
    }

    public private(set) var actions: [DebugActionType]

    public init(actions: [DebugActionType]) {
        self.actions = actions
    }

    public func addActions(_ actions: [DebugActionType]) {
        self.actions.append(contentsOf: actions)
    }
}
