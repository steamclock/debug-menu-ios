#if os(iOS)
import SwiftUI

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
    /// stops asking, including after a relaunch.
    func debugMenuTrigger(
        taps: Int = 7,
        access: DebugMenuAccessPolicy = .none,
        @DebugMenuBuilder content: @escaping @MainActor () -> DebugMenuGroup
    ) -> some View {
        modifier(DebugMenuTrigger(gesture: AnyGesture(TapGesture(count: taps)), lock: DebugMenuLock(policy: access), menu: content))
    }

    /// Opens the debug menu in a sheet when this view is long pressed for `longPressDuration` seconds.
    ///
    /// Passwords work as they do for `debugMenuTrigger(taps:access:content:)`.
    func debugMenuTrigger(
        longPressDuration: TimeInterval,
        access: DebugMenuAccessPolicy = .none,
        @DebugMenuBuilder content: @escaping @MainActor () -> DebugMenuGroup
    ) -> some View {
        let gesture = AnyGesture(LongPressGesture(minimumDuration: longPressDuration).map { _ in })
        return modifier(DebugMenuTrigger(gesture: gesture, lock: DebugMenuLock(policy: access), menu: content))
    }
}

private struct DebugMenuTrigger: ViewModifier {
    let gesture: AnyGesture<Void>
    let lock: DebugMenuLock
    let menu: @MainActor () -> DebugMenuGroup

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .gesture(gesture.onEnded { isPresented = true })
            .sheet(isPresented: $isPresented) {
                DebugMenuSheet(lock: lock, menu: menu)
            }
    }
}

private struct DebugMenuSheet: View {
    let lock: DebugMenuLock
    let menu: @MainActor () -> DebugMenuGroup

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DebugMenuNavigation {
            DebugMenuGate(lock: lock, menu: menu)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// Shows a password form until the lock is open, then the menu.
private struct DebugMenuGate: View {
    let lock: DebugMenuLock
    let menu: @MainActor () -> DebugMenuGroup

    @State private var password = ""
    @State private var hasUnlocked = false
    @State private var showsFailure = false

    var body: some View {
        if hasUnlocked || lock.isUnlocked {
            DebugMenuView(content: menu)
        } else {
            passwordForm
        }
    }

    private var passwordForm: some View {
        Form {
            Section {
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .onSubmit(submit)
                Button("Unlock", action: submit)
                    .disabled(password.isEmpty)
            } footer: {
                if showsFailure {
                    Text("Incorrect password")
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
