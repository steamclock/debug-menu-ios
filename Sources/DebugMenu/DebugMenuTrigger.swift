#if os(iOS)
import SwiftUI

@available(iOS 17, *)
public extension View {
    /// Opens the debug menu in a sheet when this view is tapped `taps` times with one finger, 7 by default.
    ///
    /// ```swift
    /// ContentView()
    ///     .debugMenuTrigger(taps: 10, access: .passwordSHA256(hash)) {
    ///         DebugToggle("Show all foos", isOn: $showAllFoos)
    ///     }
    /// ```
    ///
    /// With a password in `access`, the menu asks for it after the gesture. Once it's entered correctly the menu
    /// stops asking, including after a relaunch. The open menu refreshes when `changes` is sent.
    func debugMenuTrigger(
        taps: Int = 7,
        access: DebugMenuAccessPolicy = .none,
        changes: DebugMenuChanges = .shared,
        @DebugMenuBuilder content: @escaping @MainActor () -> DebugMenuGroup
    ) -> some View {
        let gesture = AnyGesture(TapGesture(count: taps))
        return modifier(DebugMenuTrigger(gesture: gesture, lock: DebugMenuLock(policy: access), changes: changes, menu: content))
    }

    /// Opens the debug menu in a sheet when this view is long pressed for `longPressDuration` seconds.
    ///
    /// Passwords and `changes` work as they do for `debugMenuTrigger(taps:access:changes:content:)`.
    func debugMenuTrigger(
        longPressDuration: TimeInterval,
        access: DebugMenuAccessPolicy = .none,
        changes: DebugMenuChanges = .shared,
        @DebugMenuBuilder content: @escaping @MainActor () -> DebugMenuGroup
    ) -> some View {
        let gesture = AnyGesture(LongPressGesture(minimumDuration: longPressDuration).map { _ in })
        return modifier(DebugMenuTrigger(gesture: gesture, lock: DebugMenuLock(policy: access), changes: changes, menu: content))
    }
}

@available(iOS 17, *)
private struct DebugMenuTrigger: ViewModifier {
    let gesture: AnyGesture<Void>
    let lock: DebugMenuLock
    let changes: DebugMenuChanges
    let menu: @MainActor () -> DebugMenuGroup

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .gesture(gesture.onEnded { isPresented = true })
            .sheet(isPresented: $isPresented) {
                DebugMenuSheet(lock: lock, changes: changes, menu: menu)
            }
    }
}

@available(iOS 17, *)
private struct DebugMenuSheet: View {
    private static let doneTitle = "Done"

    let lock: DebugMenuLock
    let changes: DebugMenuChanges
    let menu: @MainActor () -> DebugMenuGroup

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DebugMenuGate(lock: lock, changes: changes, menu: menu)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Self.doneTitle) { dismiss() }
                    }
                }
        }
    }
}

/// Shows a password form until the lock is open, then the menu.
@available(iOS 17, *)
private struct DebugMenuGate: View {
    private static let passwordPlaceholder = "Password"
    private static let unlockTitle = "Unlock"
    private static let failureMessage = "Incorrect password"

    let lock: DebugMenuLock
    let changes: DebugMenuChanges
    let menu: @MainActor () -> DebugMenuGroup

    @State private var password = ""
    @State private var hasUnlocked = false
    @State private var showsFailure = false

    var body: some View {
        if hasUnlocked || lock.isUnlocked {
            DebugMenuView(changes: changes, content: menu)
        } else {
            passwordForm
        }
    }

    private var passwordForm: some View {
        Form {
            Section {
                SecureField(Self.passwordPlaceholder, text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .onSubmit(submit)
                Button(Self.unlockTitle, action: submit)
                    .disabled(password.isEmpty)
            } footer: {
                if showsFailure {
                    Text(Self.failureMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(DebugMenuView.title)
    }

    private func submit() {
        hasUnlocked = lock.unlock(password: password)
        showsFailure = !hasUnlocked
    }
}
#endif
