#if os(iOS)
import SwiftUI
import UIKit

/// Picks the view for a row's kind. Each row view reads the app's value through `get` in its own `body`.
///
/// A row's closures often compare equal from one menu build to the next (a closure that captures only the app's
/// settings object, say), so SwiftUI would skip the row when the menu rebuilds. Every view that calls an app closure
/// in its `body` observes `DebugMenuChanges` itself, so it reads the value again.
struct DebugItemRow: View {
    let item: DebugItem
    let menu: DebugMenu

    var body: some View {
        switch item.kind {
        case .toggle(let get, _):
            DebugToggleRow(item: item, get: get, menu: menu)
        case .action:
            DebugActionRow(item: item, command: .runAction(rowID: item.id), menu: menu)
        case .asyncAction:
            DebugAsyncActionRow(item: item, menu: menu)
        case .info(let value):
            DebugInfoRow(item: item, value: value)
        case .picker(let picker):
            DebugPickerRow(item: item, picker: picker, menu: menu)
        case .custom(let custom):
            custom.makeView()
        }
    }
}

private struct DebugToggleRow: View {
    let item: DebugItem
    let get: @MainActor @Sendable () -> Bool
    let menu: DebugMenu

    @State private var pendingCommand: DebugCommand?

    @ObservedObject private var changes = DebugMenuChanges.shared

    var body: some View {
        Toggle(isOn: Binding(get: get, set: request)) {
            DebugRowTitle(item: item)
        }
        .disabled(item.availability.isDisabled())
        .debugConfirmation(for: item, pendingCommand: $pendingCommand, menu: menu)
    }

    private func request(_ isOn: Bool) {
        item.request(.setToggle(rowID: item.id, isOn: isOn), pendingCommand: $pendingCommand, run: menu.start)
    }
}

private struct DebugActionRow: View {
    let item: DebugItem
    let command: DebugCommand
    let menu: DebugMenu

    @State private var pendingCommand: DebugCommand?

    @ObservedObject private var changes = DebugMenuChanges.shared

    var body: some View {
        Button(role: item.buttonRole) {
            item.request(command, pendingCommand: $pendingCommand, run: menu.start)
        } label: {
            DebugRowTitle(item: item)
        }
        .disabled(item.availability.isDisabled())
        .debugConfirmation(for: item, pendingCommand: $pendingCommand, menu: menu)
    }
}

private struct DebugAsyncActionRow: View {
    let item: DebugItem
    let menu: DebugMenu

    @State private var pendingCommand: DebugCommand?
    @State private var isRunning = false
    @State private var result: DebugCommandResult?

    @ObservedObject private var changes = DebugMenuChanges.shared

    var body: some View {
        Button(role: item.buttonRole) {
            item.request(.runAsyncAction(rowID: item.id), pendingCommand: $pendingCommand, run: run)
        } label: {
            label
        }
        .disabled(item.availability.isDisabled() || isRunning)
        .debugConfirmation(for: item, pendingCommand: $pendingCommand, menu: menu, perform: run)
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                DebugRowTitle(item: item)
                Spacer()
                if isRunning {
                    ProgressView()
                } else if let result {
                    Image(systemName: result.systemImageName)
                        .foregroundColor(result.color)
                }
            }
            if let result, !isRunning {
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(result.color)
            }
        }
    }

    private func run(_ command: DebugCommand) {
        isRunning = true
        result = nil
        Task {
            result = await menu.perform(command)
            isRunning = false
        }
    }
}

private struct DebugInfoRow: View {
    private static let copiedDuration: UInt64 = 1_500_000_000
    private static let emptyValue = "None"
    private static let copiedText = "Copied"
    private static let copyHint = "Copies the value"

    let item: DebugItem
    let value: @MainActor @Sendable () -> String?

    @State private var isCopied = false

    @ObservedObject private var changes = DebugMenuChanges.shared

    var body: some View {
        let currentValue = value()
        Button {
            UIPasteboard.general.string = currentValue
            isCopied = true
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                DebugRowTitle(item: item)
                Spacer(minLength: 16)
                Text(isCopied ? Self.copiedText : currentValue ?? Self.emptyValue)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
            }
        }
        .disabled(item.availability.isDisabled() || currentValue == nil)
        .accessibilityHint(Self.copyHint)
        .task(id: isCopied) {
            guard isCopied else { return }
            // Sleep only throws on cancellation, when the row is gone and there's nothing to reset.
            try? await Task.sleep(nanoseconds: Self.copiedDuration)
            isCopied = false
        }
    }
}

private struct DebugPickerRow: View {
    let item: DebugItem
    let picker: DebugPickerConfiguration
    let menu: DebugMenu

    @ObservedObject private var changes = DebugMenuChanges.shared

    var body: some View {
        let selected = picker.selectedOption
        NavigationLink {
            DebugPickerScreen(item: item, picker: picker, menu: menu)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                DebugRowTitle(item: item)
                Spacer(minLength: 16)
                Text(selected?.title ?? "")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .disabled(item.availability.isDisabled())
    }
}

private struct DebugPickerScreen: View {
    let item: DebugItem
    let picker: DebugPickerConfiguration
    let menu: DebugMenu

    @Environment(\.dismiss) private var dismiss
    @State private var pendingCommand: DebugCommand?

    var body: some View {
        List {
            ForEach(picker.options) { option in
                DebugPickerOptionRow(option: option) { choose(option) }
            }
        }
        .navigationTitle(item.title)
        .debugConfirmation(for: item, pendingCommand: $pendingCommand, menu: menu, perform: select)
    }

    private func choose(_ option: DebugPickerOption) {
        item.request(.selectOption(rowID: item.id, optionID: option.id), pendingCommand: $pendingCommand, run: select)
    }

    private func select(_ command: DebugCommand) {
        Task {
            await menu.perform(command)
            dismiss()
        }
    }
}

private struct DebugPickerOptionRow: View {
    let option: DebugPickerOption
    let choose: @MainActor () -> Void

    @ObservedObject private var changes = DebugMenuChanges.shared

    var body: some View {
        let isSelected = option.isSelected()
        Button {
            if !isSelected {
                choose()
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .foregroundColor(.primary)
                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

private struct DebugRowTitle: View {
    let item: DebugItem

    @ObservedObject private var changes = DebugMenuChanges.shared

    var body: some View {
        let isDisabled = item.availability.isDisabled()
        VStack(alignment: .leading, spacing: 5) {
            Text(item.title)
                .foregroundColor(isDisabled ? .secondary : item.role == .destructive ? .red : .primary)
            if let helpText = item.helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if isDisabled, let reason = item.availability.disabledReason() {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private extension View {
    /// Asks before running `pendingCommand`, using the row's confirmation text. Runs it with `perform`,
    /// or dispatches it if no `perform` is given.
    func debugConfirmation(
        for item: DebugItem,
        pendingCommand: Binding<DebugCommand?>,
        menu: DebugMenu,
        perform: (@MainActor (DebugCommand) -> Void)? = nil
    ) -> some View {
        let isPresented = Binding(
            get: { pendingCommand.wrappedValue != nil },
            set: { if !$0 { pendingCommand.wrappedValue = nil } }
        )
        return confirmationDialog(
            item.confirmation?.title ?? item.title,
            isPresented: isPresented,
            titleVisibility: .visible,
            presenting: pendingCommand.wrappedValue
        ) { command in
            Button(item.confirmation?.confirmTitle ?? "", role: item.buttonRole) {
                (perform ?? menu.start)(command)
            }
            Button(item.confirmation?.cancelTitle ?? "", role: .cancel) {}
        } message: { _ in
            if let message = item.confirmation?.message {
                Text(message)
            }
        }
    }
}

private extension DebugItem {
    var buttonRole: ButtonRole? {
        role == .destructive ? .destructive : nil
    }

    /// Runs `command` now, or holds it in `pendingCommand` for the confirmation dialog when the row has one.
    @MainActor
    func request(
        _ command: DebugCommand,
        pendingCommand: Binding<DebugCommand?>,
        run: @MainActor (DebugCommand) -> Void
    ) {
        if confirmation == nil {
            run(command)
        } else {
            pendingCommand.wrappedValue = command
        }
    }
}

private extension DebugCommandResult {
    private static let successMessage = "Succeeded"
    private static let failurePrefix = "Failed: "

    var message: String {
        switch self {
        case .success: Self.successMessage
        case .failure(.actionFailed(_, let message)): Self.failurePrefix + message
        case .failure(let error): Self.failurePrefix + String(describing: error)
        }
    }

    var systemImageName: String {
        self == .success ? "checkmark.circle" : "exclamationmark.triangle"
    }

    var color: Color {
        self == .success ? .green : .red
    }
}
#endif
