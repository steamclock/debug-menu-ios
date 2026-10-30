import XCTest
@testable import DebugMenu

@MainActor
final class DebugDefaultsTests: XCTestCase {
    private enum Server: String, Sendable {
        case production
        case staging
    }

    func testDefaultsAppearOnlyWhenAddedAndDispatch() async throws {
        var server = Server.production
        var isLogging = false
        var sentLogs: [DebugLogFile] = []
        let log = DebugLogFile.data(Data("hello".utf8), fileName: "app.log")

        let menu = DebugMenu {
            DebugPicker.environment(options: [Server.production, .staging], get: { server }, set: { server = $0 })
            DebugToggle.advancedLogging(get: { isLogging }, set: { isLogging = $0 })
            DebugButton.sendLogs(logs: { [log] }, destination: .custom { sentLogs = $0 })
        }

        XCTAssertEqual(menu.snapshot().nodes.map(\.id), ["Environment", "Advanced logging", "Send logs"])
        guard case .picker(_, let options) = menu.snapshot().nodes[0].content else {
            return XCTFail("Expected a picker")
        }
        XCTAssertEqual(options.map(\.title), ["production", "staging"])
        XCTAssertEqual(DebugMenu { DebugToggle("Other", get: { true }, set: { _ in }) }.snapshot().nodes.count, 1)

        _ = await menu.dispatch(.selectOption(rowID: "Environment", optionID: "staging"))
        _ = await menu.dispatch(.setToggle(rowID: "Advanced logging", isOn: true))
        _ = await menu.dispatch(.runAsyncAction(rowID: "Send logs"))

        XCTAssertEqual(server, .staging)
        XCTAssertTrue(isLogging)
        XCTAssertEqual(sentLogs, [log])
    }
}
