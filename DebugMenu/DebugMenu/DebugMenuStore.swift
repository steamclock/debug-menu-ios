import Combine
import Foundation

public class DebugMenuStore: BaseDebugDataSource {

    public static let shared = DebugMenuStore()

}

open class BaseDebugDataSource: DebugMenuDataSource {

    open var navigationTitle: String {
        "Debug Menu"
    }

    public private(set) var actions: [DebugActionType]

    public init(actions: [DebugActionType] = []) {
        self.actions = actions
    }

    public func addAction(_ action: DebugActionType) {
        self.actions.append(action)
    }
}
