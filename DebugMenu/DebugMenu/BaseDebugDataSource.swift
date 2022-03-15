import Combine
import Foundation

open class BaseDebugDataSource: DebugMenuDataSource {

    open var navigationTitle: String {
        "Debug Menu"
    }

    public private(set) var actions: [DebugAction]

    public init(actions: [DebugAction] = []) {
        self.actions = actions
    }

    public func addAction(_ action: DebugAction) {
        self.actions.append(action)
    }

    public func addActions(_ actions: [DebugAction]) {
        self.actions.append(contentsOf: actions)
    }

    open var includeCommonOptions: Bool {
        false
    }

    @Published public var debugAlert: DebugAlert?
}
