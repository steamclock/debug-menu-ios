#if os(iOS)
import os
import SwiftUI
import UIKit

private let logger = Logger(subsystem: "DebugMenu", category: "DebugConfirmation")

extension DebugItem {
    var buttonRole: ButtonRole? {
        role == .destructive ? .destructive : nil
    }

    /// Runs `command` now, or after the user confirms it when the row has a confirmation.
    ///
    /// The confirmation is a UIKit action sheet so it slides up from the bottom. From iOS 26, SwiftUI's
    /// `confirmationDialog` shows as a popover over the row, or centered on screen, instead.
    @MainActor
    func request(_ command: DebugCommand, run: @escaping @MainActor @Sendable (DebugCommand) -> Void) {
        guard let confirmation else {
            return run(command)
        }
        let sheet = UIAlertController(title: confirmation.title, message: confirmation.message, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: confirmation.confirmTitle, style: role == .destructive ? .destructive : .default) { _ in
            run(command)
        })
        sheet.addAction(UIAlertAction(title: confirmation.cancelTitle, style: .cancel))
        do {
            try presentOverMenu(sheet)
        } catch {
            let errorDescription = String(describing: error)
            logger.error("Couldn't show debug menu confirmation. row: \(id, privacy: .public), error: \(errorDescription)")
        }
    }
}
#endif
