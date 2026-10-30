import XCTest
@testable import DebugMenu

@MainActor
final class DebugMenuRemoteTests: XCTestCase {
    /// Drives the menu the way a remote would: JSON snapshot in, JSON commands out, no closures held.
    func testMenuCanBeDrivenWithSnapshotAndCommandsAlone() async throws {
        let app = TestAppState()
        let menu = makeFullMenu(app)
        let remote = RemoteStandIn(menu: menu)

        var rows = try remote.fetchRows()
        let toggle = try XCTUnwrap(rows.first { $0.title == "Show all foos" })
        let picker = try XCTUnwrap(rows.first { $0.title == "Environment" })
        let reset = try XCTUnwrap(rows.first { $0.title == "Reset" })
        let sync = try XCTUnwrap(rows.first { $0.title == "Sync" })
        let staging = try XCTUnwrap(picker.pickerOptions?.first { $0.title == "Staging" })

        XCTAssertEqual(toggle.content, .toggle(isOn: false))
        XCTAssertEqual(picker.selectedOptionID, "production")
        XCTAssertEqual(toggle.helpText, "Shows every foo")

        try await XCTAssertSuccess(remote.send(.setToggle(rowID: toggle.id, isOn: true)))
        try await XCTAssertSuccess(remote.send(.selectOption(rowID: picker.id, optionID: staging.id)))
        try await XCTAssertSuccess(remote.send(.runAction(rowID: reset.id)))
        try await XCTAssertSuccess(remote.send(.runAsyncAction(rowID: sync.id)))

        XCTAssertTrue(app.showAllFoos)
        XCTAssertEqual(app.environment, .staging)
        XCTAssertEqual(app.resetCount, 1)
        XCTAssertEqual(app.syncCount, 1)

        rows = try remote.fetchRows()
        XCTAssertEqual(rows.first { $0.id == toggle.id }?.content, .toggle(isOn: true))
        XCTAssertEqual(rows.first { $0.id == picker.id }?.selectedOptionID, staging.id)
    }

    func testSnapshotDescribesTree() throws {
        let app = TestAppState()
        let snapshot = makeFullMenu(app).snapshot()

        XCTAssertEqual(snapshot.nodes.map(\.kind), [.section, .submenu])
        XCTAssertEqual(snapshot.nodes[0].children?.map(\.kind), [.toggle, .picker, .picker, .info, .custom])
        XCTAssertEqual(snapshot.nodes[1].children?.map(\.kind), [.action, .asyncAction, .asyncAction, .action])

        let server = try XCTUnwrap(snapshot.nodes[0].children?[2])
        XCTAssertEqual(server.pickerOptions?.map(\.id), ["https://prod.example.com", "https://staging.example.com"])
        XCTAssertEqual(server.selectedOptionID, "https://prod.example.com")
        XCTAssertEqual(snapshot.nodes[0].children?[3].content, .info(text: "12 KB"))
        XCTAssertEqual(snapshot.nodes[0].children?[4].content, .custom(text: "custom text"))
        XCTAssertEqual(snapshot.nodes[1].children?[3].isDisabled, true)
    }

    func testSnapshotsAreIdenticalAcrossBuilds() throws {
        let app = TestAppState()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        XCTAssertEqual(
            try encoder.encode(makeFullMenu(app).snapshot()),
            try encoder.encode(makeFullMenu(app).snapshot())
        )
    }

    func testCommandErrors() async {
        let app = TestAppState()
        let menu = makeFullMenu(app)

        let unknownRow = await menu.dispatch(.runAction(rowID: "Nope"))
        let wrongKind = await menu.dispatch(.runAction(rowID: "Actions/Sync"))
        let unknownOption = await menu.dispatch(.selectOption(rowID: "Features/Environment", optionID: "moon"))
        let unavailable = await menu.dispatch(.runAction(rowID: "Actions/Locked"))
        let failed = await menu.dispatch(.runAsyncAction(rowID: "Actions/Fail"))

        XCTAssertEqual(unknownRow, .failure(.unknownRow(rowID: "Nope")))
        XCTAssertEqual(wrongKind, .failure(.wrongKind(rowID: "Actions/Sync", kind: .asyncAction)))
        XCTAssertEqual(unknownOption, .failure(.unknownOption(rowID: "Features/Environment", optionID: "moon")))
        XCTAssertEqual(unavailable, .failure(.unavailable(rowID: "Actions/Locked")))
        XCTAssertEqual(failed, .failure(.actionFailed(rowID: "Actions/Fail", message: "expected")))
    }

    func testDispatchSignalsChanges() async {
        let app = TestAppState()
        let menu = makeFullMenu(app)
        let before = DebugMenuChanges.shared.generation

        _ = await menu.dispatch(.setToggle(rowID: "Features/Show all foos", isOn: true))

        XCTAssertEqual(DebugMenuChanges.shared.generation, before + 1)
    }
}

/// Talks to the menu only through encoded snapshots, commands and results, as a remote would.
@MainActor
private struct RemoteStandIn {
    let menu: DebugMenu

    func fetchRows() throws -> [DebugMenuSnapshot.Node] {
        let snapshot = try JSONDecoder().decode(DebugMenuSnapshot.self, from: JSONEncoder().encode(menu.snapshot()))
        return flatten(snapshot.nodes)
    }

    func send(_ command: DebugCommand) async throws -> DebugCommandResult {
        let received = try JSONDecoder().decode(DebugCommand.self, from: JSONEncoder().encode(command))
        let result = await menu.dispatch(received)
        return try JSONDecoder().decode(DebugCommandResult.self, from: JSONEncoder().encode(result))
    }

    private func flatten(_ nodes: [DebugMenuSnapshot.Node]) -> [DebugMenuSnapshot.Node] {
        nodes.flatMap { [$0] + flatten($0.children ?? []) }
    }
}

private func XCTAssertSuccess(_ result: DebugCommandResult, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(result, .success, file: file, line: line)
}

private extension DebugMenuSnapshot.Node {
    var pickerOptions: [DebugMenuSnapshot.Option]? {
        guard case .picker(_, let options) = content else { return nil }
        return options
    }

    var selectedOptionID: String? {
        guard case .picker(let selectedOptionID, _) = content else { return nil }
        return selectedOptionID
    }
}
