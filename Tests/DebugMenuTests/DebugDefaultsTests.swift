import XCTest
@testable import DebugMenu

@MainActor
final class DebugDefaultsTests: XCTestCase {
    private enum Server: DebugEnvironment {
        case production
        case staging
        case custom(URL)

        var title: String {
            switch self {
            case .production: "Production"
            case .staging: "Staging"
            case .custom: "Custom"
            }
        }

        var url: URL {
            switch self {
            case .production: URL(string: "https://api.example.com")!
            case .staging: URL(string: "https://staging.example.com")!
            case .custom(let url): url
            }
        }
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
        guard case .picker(_, let options, let acceptsCustomURL) = menu.snapshot().nodes[0].content else {
            return XCTFail("Expected a picker")
        }
        XCTAssertEqual(options.map(\.title), ["Production", "Staging"])
        XCTAssertEqual(options.map(\.subtitle), ["https://api.example.com", "https://staging.example.com"])
        XCTAssertFalse(acceptsCustomURL)
        XCTAssertEqual(DebugMenu { DebugToggle("Other", get: { true }, set: { _ in }) }.snapshot().nodes.count, 1)

        _ = await menu.dispatch(.selectOption(rowID: "Environment", optionID: "staging"))
        _ = await menu.dispatch(.setToggle(rowID: "Advanced logging", isOn: true))
        _ = await menu.dispatch(.runAsyncAction(rowID: "Send logs"))
        let customURL = await menu.dispatch(.setCustomURL(rowID: "Environment", url: URL(string: "https://dev.example.com")!))

        XCTAssertEqual(server, .staging)
        XCTAssertTrue(isLogging)
        XCTAssertEqual(sentLogs, [log])
        XCTAssertEqual(customURL, .failure(.customURLUnsupported(rowID: "Environment")))
    }

    func testCustomURLSetsEnvironmentAndShowsAsSelectedOption() async throws {
        var server = Server.production
        let menu = DebugMenu {
            DebugPicker.environment(options: [Server.production, .staging], get: { server }, set: { server = $0 },
                                    custom: { .custom($0) })
        }
        let localURL = URL(string: "http://localhost:8080")!

        let result = await menu.dispatch(.setCustomURL(rowID: "Environment", url: localURL))

        XCTAssertEqual(result, .success)
        XCTAssertEqual(server, .custom(localURL))
        guard case .picker(let selectedOptionID, let options, let acceptsCustomURL) = menu.snapshot().nodes[0].content else {
            return XCTFail("Expected a picker")
        }
        XCTAssertTrue(acceptsCustomURL)
        XCTAssertEqual(options.map(\.title), ["Production", "Staging", "Custom"])
        XCTAssertEqual(options.last?.subtitle, "http://localhost:8080")
        XCTAssertEqual(selectedOptionID, options.last?.id)
    }

    func testCustomURLRejectsNonServerURLs() async {
        var server = Server.production
        let menu = DebugMenu {
            DebugPicker.environment(options: [Server.production], get: { server }, set: { server = $0 },
                                    custom: { .custom($0) })
        }

        for string in ["file:///etc/hosts", "ftp://example.com", "https://"] {
            let url = URL(string: string)!
            let result = await menu.dispatch(.setCustomURL(rowID: "Environment", url: url))
            XCTAssertEqual(result, .failure(.invalidURL(rowID: "Environment", url: url)), string)
        }
        XCTAssertEqual(server, .production)
    }
}
