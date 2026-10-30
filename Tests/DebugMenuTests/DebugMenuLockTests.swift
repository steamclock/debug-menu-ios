import XCTest
@testable import DebugMenu

final class DebugMenuLockTests: XCTestCase {
    private static let suiteName = "DebugMenuLockTests"
    // SHA-256 of "debug".
    private static let debugHash = "0b8e9e995d8d77f1e4770f0f79665aee6f3f70247b3735422daba73df4c3096f"

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: Self.suiteName)
        defaults.removePersistentDomain(forName: Self.suiteName)
    }

    func testNoPasswordByDefault() {
        let lock = DebugMenuLock(policy: .none, defaults: defaults)

        XCTAssertTrue(lock.isUnlocked)
        XCTAssertNil(defaults.object(forKey: DebugMenuLock.unlockedKey))
    }

    func testCorrectPasswordUnlockPersists() {
        let lock = DebugMenuLock(policy: .passwordSHA256(Self.debugHash), defaults: defaults)
        XCTAssertFalse(lock.isUnlocked)

        XCTAssertFalse(lock.unlock(password: "release"))
        XCTAssertFalse(lock.isUnlocked)

        XCTAssertTrue(lock.unlock(password: "debug"))
        XCTAssertTrue(lock.isUnlocked)

        // A new lock reading the same defaults stands in for a relaunch.
        XCTAssertTrue(DebugMenuLock(policy: .passwordSHA256(Self.debugHash), defaults: defaults).isUnlocked)
    }

    func testChangedPasswordLocksAgain() {
        // SHA-256 of "release".
        let releaseHash = "a4d451ec23463726f72c43d64c710968f6b602cd653b4de8adee1b556240a829"
        XCTAssertTrue(DebugMenuLock(policy: .passwordSHA256(Self.debugHash), defaults: defaults).unlock(password: "debug"))

        XCTAssertFalse(DebugMenuLock(policy: .passwordSHA256(releaseHash), defaults: defaults).isUnlocked)
    }

    func testAccessPolicy() {
        XCTAssertTrue(DebugMenuAccessPolicy.passwordSHA256(Self.debugHash).allowsAccess(password: "debug"))
        XCTAssertFalse(DebugMenuAccessPolicy.passwordSHA256(Self.debugHash).allowsAccess(password: "release"))
        XCTAssertTrue(DebugMenuAccessPolicy.custom { $0 == "zipline" }.allowsAccess(password: "zipline"))
        XCTAssertFalse(DebugMenuAccessPolicy.custom { $0 == "zipline" }.allowsAccess(password: "other"))
    }
}
