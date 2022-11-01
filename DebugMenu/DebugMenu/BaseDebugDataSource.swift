import Combine
import Foundation

open class BaseDebugDataSource: DebugMenuDataSource {

    open var navigationTitle: String {
        "Debug Menu"
    }

    @Published public private(set) var sections: [DebugSection]

    @Published public var debugAlert: DebugAlert?

    @Published public var isLoading: Bool = false

    public init(sections: [DebugSection] = []) {
        self.sections = sections
    }

    public func addSection(_ section: DebugSection) {
        self.sections.append(section)
    }

    public func addSections(_ sections: [DebugSection]) {
        self.sections.append(contentsOf: sections)
    }

    open var includeCommonOptions: Bool {
        false
    }
}
