import CryptoKit
import Foundation

/// Whether the menu asks for a password before it opens. `.none`, the default, never asks.
public enum DebugMenuAccessPolicy: Sendable {
    /// No password.
    case none
    /// A password, given as the hex SHA-256 hash of the password so the password isn't in the app as plain text.
    /// The hash is unsalted, so a short password can be recovered from the binary. It keeps casual users out of the
    /// menu, nothing more.
    case passwordSHA256(String)
    /// A password checked by your own closure. The menu can't tell one closure from another, so `id` names this
    /// check in the remembered unlock. Change `id` when you change the check, to lock the menu again.
    case custom(id: String, @Sendable (String) -> Bool)

    /// Whether `password` passes the policy. Always true for `.none`.
    public func allowsAccess(password: String) -> Bool {
        switch self {
        case .none:
            true
        case .passwordSHA256(let expectedHash):
            Self.sha256Hex(password).caseInsensitiveCompare(expectedHash) == .orderedSame
        case .custom(_, let validator):
            validator(password)
        }
    }

    /// What the lock stores after a correct password, so a changed hash or custom `id` locks the menu again. `nil`
    /// when there's no password.
    var unlockToken: String? {
        switch self {
        case .none:
            nil
        case .passwordSHA256(let expectedHash):
            expectedHash.lowercased()
        case .custom(let id, _):
            Self.customUnlockTokenPrefix + id
        }
    }

    private static let customUnlockTokenPrefix = "custom:"

    private static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
