import CryptoKit
import Foundation

/// Whether the menu asks for a password before it opens. `.none`, the default, never asks.
public enum DebugMenuAccessPolicy: Sendable {
    /// No password.
    case none
    /// A password, given as the hex SHA-256 hash of the password so the password itself isn't in the app.
    case passwordSHA256(String)
    /// A password checked by your own closure.
    case custom(@Sendable (String) -> Bool)

    /// Whether `password` passes the policy. Always true for `.none`.
    public func allowsAccess(password: String) -> Bool {
        switch self {
        case .none:
            true
        case .passwordSHA256(let expectedHash):
            Self.sha256Hex(password).caseInsensitiveCompare(expectedHash) == .orderedSame
        case .custom(let validator):
            validator(password)
        }
    }

    var requiresChallenge: Bool {
        switch self {
        case .none:
            false
        case .passwordSHA256, .custom:
            true
        }
    }

    private static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
