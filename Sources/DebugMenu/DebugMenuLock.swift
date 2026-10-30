import Foundation

/// Decides whether the menu needs a password, and remembers a correct one across launches.
///
/// Only an "unlocked" flag is stored, never the password.
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
        !policy.requiresChallenge || defaults.bool(forKey: Self.unlockedKey)
    }

    /// Returns whether `password` is correct, and if it is, remembers the unlock.
    func unlock(password: String) -> Bool {
        guard policy.allowsAccess(password: password) else {
            return false
        }
        defaults.set(true, forKey: Self.unlockedKey)
        return true
    }
}
