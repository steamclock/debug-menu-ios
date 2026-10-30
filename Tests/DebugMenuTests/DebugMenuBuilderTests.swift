import SwiftUI
import XCTest
@testable import DebugMenu

@MainActor
final class DebugMenuBuilderTests: XCTestCase {
    func testBuildsTreeWithStablePathIDs() {
        let app = TestAppState()
        let menu = DebugMenu {
            DebugInfo("Build", value: "42")
            DebugSection("Features") {
                DebugToggle("Show all foos", get: { app.showAllFoos }, set: { app.showAllFoos = $0 })
                DebugButton("Reset onboarding") { app.resetCount += 1 }
                DebugSubmenu("Cache") {
                    DebugInfo("Size", value: app.cacheSize)
                    DebugButton("Clear", role: .destructive, confirmation: .required("Clear cache?")) {
                        app.cacheSize = "0 KB"
                    }
                }
                DebugCustom("Custom", value: "custom text") { Text("Hello") }
            }
        }

        XCTAssertEqual(allIDs(menu.children), [
            "Build",
            "Features",
            "Features/Show all foos",
            "Features/Reset onboarding",
            "Features/Cache",
            "Features/Cache/Size",
            "Features/Cache/Clear",
            "Features/Custom"
        ])

        guard case .container(let features) = menu.children[1], case .container(let cache) = features.children[2] else {
            return XCTFail("Expected a section containing a submenu")
        }
        XCTAssertEqual(features.style, .section)
        XCTAssertEqual(cache.style, .submenu)
        XCTAssertEqual(menu.itemsByID["Features/Cache/Clear"]?.role, .destructive)
        XCTAssertEqual(menu.itemsByID["Features/Cache/Clear"]?.confirmation?.title, "Clear cache?")
        guard case .custom(let custom) = menu.itemsByID["Features/Custom"]?.kind else {
            return XCTFail("Expected a custom row")
        }
        XCTAssertEqual(custom.text(), "custom text")
    }

    func testIDsAreIdenticalAcrossBuilds() {
        let app = TestAppState()
        XCTAssertEqual(allIDs(makeFullMenu(app).children), allIDs(makeFullMenu(app).children))
    }

    func testControlFlow() {
        let app = TestAppState()

        func build(isLoggedIn: Bool) -> [String] {
            allIDs(DebugMenu {
                if isLoggedIn {
                    DebugButton("Log out") {}
                } else {
                    DebugButton("Log in") {}
                }
                if isLoggedIn {
                    DebugInfo("User", value: "abc")
                }
                for server in ["prod", "staging"] {
                    DebugButton("Ping \(server)") {}
                }
                if #available(iOS 15, macOS 12, *) {
                    DebugToggle("Available", get: { app.showAllFoos }, set: { app.showAllFoos = $0 })
                }
            }.children)
        }

        XCTAssertEqual(build(isLoggedIn: true), ["Log out", "User", "Ping prod", "Ping staging", "Available"])
        XCTAssertEqual(build(isLoggedIn: false), ["Log in", "Ping prod", "Ping staging", "Available"])
    }

    func testExtractedContentType() {
        let app = TestAppState()
        let menu = DebugMenu {
            DebugSubmenu("Cache") {
                CacheMenu(app: app)
            }
            CacheMenu(app: app)
        }

        XCTAssertEqual(allIDs(menu.children), ["Cache", "Cache/Size", "Cache/Clear", "Size", "Clear"])
    }

    func testExplicitIDReplacesTitle() {
        let app = TestAppState()
        let menu = DebugMenu {
            DebugSection("Account \(app.resetCount)") {
                DebugInfo("Logged in as \(app.cacheSize)", value: nil).id("user")
            }
            .id("account")
        }

        XCTAssertEqual(allIDs(menu.children), ["account", "account/user"])
    }

    func testDuplicateIDsGetNumberedSuffixes() {
        let menu = DebugMenu {
            DebugButton("Reset") {}
            DebugButton("Reset") {}
            DebugSection("Reset") {
                DebugButton("Reset") {}
            }
            DebugButton("Other") {}.id("Reset")
        }

        XCTAssertEqual(allIDs(menu.children), ["Reset", "Reset#2", "Reset#3", "Reset#3/Reset", "Reset#4"])
        XCTAssertEqual(menu.itemsByID.count, 4)
    }

    func testModifiers() {
        let app = TestAppState()
        let menu = DebugMenu {
            DebugToggle("Flag", get: { app.showAllFoos }, set: { app.showAllFoos = $0 })
                .help("Shows every foo")
                .hidden(!app.isLoggedIn)
                .disabled(app.cacheSize.isEmpty, reason: "Nothing cached")
        }
        let availability = menu.itemsByID["Flag"]?.availability

        XCTAssertEqual(menu.itemsByID["Flag"]?.helpText, "Shows every foo")
        XCTAssertEqual(availability?.isVisible(), false)
        XCTAssertEqual(availability?.isDisabled(), false)

        app.isLoggedIn = true
        app.cacheSize = ""

        XCTAssertEqual(availability?.isVisible(), true)
        XCTAssertEqual(availability?.isDisabled(), true)
        XCTAssertEqual(availability?.disabledReason(), "Nothing cached")
    }

    func testBindingInitsReadAndWriteThroughBinding() {
        let app = TestAppState()
        let isOn = Binding(get: { app.showAllFoos }, set: { app.showAllFoos = $0 })
        let selection = Binding(get: { app.environment }, set: { app.environment = $0 })
        let menu = DebugMenu {
            DebugToggle("Flag", isOn: isOn)
            DebugPicker("Environment", selection: selection)
        }

        guard case .toggle(let get, let set) = menu.itemsByID["Flag"]?.kind,
              case .picker(let picker) = menu.itemsByID["Environment"]?.kind else {
            return XCTFail("Expected a toggle and a picker")
        }
        set(true)
        picker.options.first { $0.id == "staging" }?.select()

        XCTAssertTrue(get())
        XCTAssertTrue(app.showAllFoos)
        XCTAssertEqual(app.environment, .staging)
    }
}

struct CacheMenu: DebugMenuContent {
    let app: TestAppState

    var body: DebugMenuGroup {
        DebugInfo("Size", value: app.cacheSize)
        DebugButton("Clear", role: .destructive) { app.cacheSize = "0 KB" }
    }
}

/// A menu that uses every row kind.
@MainActor
func makeFullMenu(_ app: TestAppState) -> DebugMenu {
    DebugMenu {
        DebugSection("Features") {
            DebugToggle("Show all foos", get: { app.showAllFoos }, set: { app.showAllFoos = $0 })
                .help("Shows every foo")
            DebugPicker("Environment", get: { app.environment }, set: { app.environment = $0 })
            DebugPicker(
                "Server",
                options: ["https://prod.example.com", "https://staging.example.com"],
                optionTitle: { $0 },
                get: { app.server },
                set: { app.server = $0 }
            )
            DebugInfo("Cache size", value: app.cacheSize)
            DebugCustom("Custom", value: "custom text") { Text("Hello") }
        }
        DebugSubmenu("Actions") {
            DebugButton("Reset") { app.resetCount += 1 }
            DebugButton("Sync") { try await app.sync() }
            DebugButton("Fail") { throw TestDebugError.expected }
            DebugButton("Locked") {}.disabled(true)
        }
    }
}

func allIDs(_ nodes: [DebugMenuNode]) -> [String] {
    nodes.flatMap { node -> [String] in
        switch node {
        case .row(let item): [item.id]
        case .container(let container): [container.id] + allIDs(container.children)
        }
    }
}
