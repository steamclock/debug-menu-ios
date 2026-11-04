import Foundation

/// Decides whether the menu needs a password, and remembers a correct one across launches.
///
/// Only a marker of which policy was unlocked is stored, never the password. Changing the password hash locks the
/// menu again.
@available(iOS 17, *)
struct DebugMenuLock {
    static let unlockedKey = "DebugMenu.isUnlocked"

    let policy: DebugMenuAccessPolicy
    let defaults: UserDefaults

    init(policy: DebugMenuAccessPolicy, defaults: UserDefaults = .standard) {
        self.policy = policy
        self.defaults = defaults
    }

    /// True when the policy has no password, or a correct one was entered before.
    var isUnlocked: Bool {
        guard let unlockToken = policy.unlockToken else {
            return true
        }
        return defaults.string(forKey: Self.unlockedKey) == unlockToken
    }

    /// Returns whether `password` is correct, and if it is, remembers the unlock.
    func unlock(password: String) -> Bool {
        guard policy.allowsAccess(password: password) else {
            return false
        }
        defaults.set(policy.unlockToken, forKey: Self.unlockedKey)
        return true
    }
}
