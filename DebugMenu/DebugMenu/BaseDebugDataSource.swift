import Combine
import Foundation

open class BaseDebugDataSource: DebugMenuDataSource {

    open var navigationTitle: String {
        "Debug Menu"
    }

    @Published public private(set) var sections: [DebugSection]

    @Published public var debugAlert: DebugAlert?

    private var defaultSection = DebugSection(title: "", actions: [])

    public init(sections: [DebugSection] = []) {
        self.sections = sections
    }

    public init(actions: [DebugAction]) {
        defaultSection.addActions(actions)
        self.sections = [defaultSection]
    }

    public func addSection(_ section: DebugSection) {
        self.sections.append(section)
    }

    public func addSections(_ sections: [DebugSection]) {
        self.sections.append(contentsOf: sections)
    }

    public func addActions(actions: [DebugAction], to section: DebugSection? = nil) {
        if let sectionIndex = self.sections.firstIndex(where: { $0 == section}) {
            self.sections[sectionIndex].addActions(actions)
        } else {
            defaultSection.addActions(actions)
            if let defaultSectionIndex = self.sections.firstIndex(where: { $0 == defaultSection}) {
                self.sections[defaultSectionIndex] = defaultSection
            } else {
                self.sections.append(defaultSection)
            }
        }
    }

    open var includeCommonOptions: Bool {
        false
    }
}
