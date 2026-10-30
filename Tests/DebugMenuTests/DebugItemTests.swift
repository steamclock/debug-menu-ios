import XCTest
@testable import DebugMenu

@MainActor
final class DebugItemTests: XCTestCase {
    func testEnumPickerConfiguration() {
        var state = AlertState.all
        let configuration = DebugPickerConfiguration(get: { state }, set: { state = $0 })

        XCTAssertEqual(configuration.selectedOption?.title, "All alerts")
        XCTAssertEqual(configuration.options.map(\.title), ["All alerts", "Critical only", "Disabled"])
        XCTAssertEqual(configuration.options.map(\.id), ["all", "criticalOnly", "disabled"])
        XCTAssertEqual(configuration.options[0].subtitle, "Every test alert is shown")

        let disabled = configuration.options[2]
        disabled.select()

        XCTAssertEqual(state, .disabled)
        XCTAssertTrue(disabled.isSelected())
    }

    func testMutuallyExclusiveStateCanBeRepresentedAsPicker() {
        var environment = EnvironmentState.production
        let configuration = DebugPickerConfiguration(get: { environment }, set: { environment = $0 })

        configuration.options.first { $0.title == "Staging" }?.select()

        XCTAssertEqual(environment, .staging)
        XCTAssertEqual(configuration.selectedOption?.title, "Staging")
    }

    func testExplicitOptionListPicker() {
        var server = "https://prod.example.com"
        let configuration = DebugPickerConfiguration(
            options: ["https://prod.example.com", "https://staging.example.com"],
            title: { URL(string: $0)?.host ?? $0 },
            get: { server },
            set: { server = $0 }
        )

        XCTAssertEqual(configuration.options.map(\.title), ["prod.example.com", "staging.example.com"])
        XCTAssertEqual(configuration.selectedOption?.id, "https://prod.example.com")

        configuration.options[1].select()

        XCTAssertEqual(server, "https://staging.example.com")

        server = "https://not-listed.example.com"

        XCTAssertNil(configuration.selectedOption)
    }

    func testAsyncActionRunsAndThrows() async throws {
        var didRun = false
        let success = DebugItemKind.asyncAction { didRun = true }
        let failure = DebugItemKind.asyncAction { throw TestDebugError.expected }

        guard case .asyncAction(let runSuccess) = success, case .asyncAction(let runFailure) = failure else {
            return XCTFail("Expected async actions")
        }

        try await runSuccess()
        XCTAssertTrue(didRun)

        do {
            try await runFailure()
            XCTFail("Expected async action to throw")
        } catch TestDebugError.expected {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConfirmedDestructiveActionMetadata() {
        let confirmation = DebugConfirmation.required("Crash app?")
        let item = DebugItem(
            id: "fake-crash",
            title: "Fake Crash",
            kind: .action({}),
            role: .destructive,
            confirmation: confirmation
        )

        XCTAssertEqual(item.role, .destructive)
        XCTAssertEqual(item.confirmation, confirmation)
        XCTAssertEqual(confirmation.confirmTitle, "Continue")
        XCTAssertEqual(confirmation.cancelTitle, "Cancel")
    }

    @MainActor
    func testToggleConfirmationModifier() {
        let confirmation = DebugConfirmation.required("Switch?")
        let toggle = DebugToggle("Flag", get: { false }, set: { _ in }).confirmation(confirmation)

        XCTAssertEqual(toggle.item.confirmation, confirmation)
    }

    func testAvailabilityIsReadEachTime() {
        let app = TestAppState()
        let availability = DebugItemAvailability(
            visibleWhen: { app.isLoggedIn },
            disabledWhen: { !app.isLoggedIn },
            disabledReason: { app.isLoggedIn ? nil : "Log in first" }
        )

        XCTAssertFalse(availability.isVisible())
        XCTAssertTrue(availability.isDisabled())
        XCTAssertEqual(availability.disabledReason(), "Log in first")

        app.isLoggedIn = true

        XCTAssertTrue(availability.isVisible())
        XCTAssertFalse(availability.isDisabled())
        XCTAssertNil(availability.disabledReason())
        XCTAssertTrue(DebugItemAvailability.enabled.isVisible())
        XCTAssertFalse(DebugItemAvailability.enabled.isDisabled())
    }
}

enum AlertState: DebugPickerValue {
    case all
    case criticalOnly
    case disabled

    var debugTitle: String {
        switch self {
        case .all: "All alerts"
        case .criticalOnly: "Critical only"
        case .disabled: "Disabled"
        }
    }

    var debugSubtitle: String? {
        switch self {
        case .all: "Every test alert is shown"
        case .criticalOnly: "Only high priority alerts are shown"
        case .disabled: "Alerts are suppressed"
        }
    }
}

enum EnvironmentState: DebugPickerValue {
    case production
    case staging
    case local

    var debugTitle: String {
        switch self {
        case .production: "Production"
        case .staging: "Staging"
        case .local: "Local"
        }
    }
}

/// Stands in for the app-owned state the menu reads and writes.
@MainActor
final class TestAppState {
    var isLoggedIn = false
    var showAllFoos = false
    var environment = EnvironmentState.production
    var server = "https://prod.example.com"
    var cacheSize = "12 KB"
    var resetCount = 0
    var syncCount = 0

    func sync() async throws {
        await Task.yield()
        syncCount += 1
    }
}

enum TestDebugError: Error {
    case expected
}
