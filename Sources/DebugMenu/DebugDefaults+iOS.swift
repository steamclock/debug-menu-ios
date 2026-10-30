#if os(iOS)
import UIKit

private enum DefaultInfo {
    static let buildName = "Build name"
    static let buildVersion = "Build version"
    static let deviceName = "Device name"
    static let systemVersion = "iOS version"
    static let displayNameKey = "CFBundleDisplayName"
    static let nameKey = "CFBundleName"
    static let versionKey = "CFBundleShortVersionString"
    static let buildKey = "CFBundleVersion"
}

@MainActor
public extension DebugInfo {
    /// The app's display name, or its bundle name if it has no display name.
    static var buildName: DebugInfo {
        DebugInfo(DefaultInfo.buildName, value: Self.infoString(DefaultInfo.displayNameKey) ?? Self.infoString(DefaultInfo.nameKey))
    }

    /// The app's version and build number, e.g. "1.2 (45)".
    static var buildVersion: DebugInfo {
        DebugInfo(DefaultInfo.buildVersion, value: Self.infoString(DefaultInfo.versionKey).map { version in
            Self.infoString(DefaultInfo.buildKey).map { "\(version) (\($0))" } ?? version
        })
    }

    /// The device's name, from `UIDevice.name`.
    ///
    /// Since iOS 16 this is only the model, such as "iPhone", unless the app has the
    /// `com.apple.developer.device-information.user-assigned-device-name` entitlement.
    static var deviceName: DebugInfo {
        DebugInfo(DefaultInfo.deviceName, value: UIDevice.current.name)
    }

    /// The iOS version, e.g. "17.4".
    static var systemVersion: DebugInfo {
        DebugInfo(DefaultInfo.systemVersion, value: UIDevice.current.systemVersion)
    }

    /// Build name, build version, device name and iOS version, in that order.
    @DebugMenuBuilder
    static var defaults: DebugMenuGroup {
        buildName
        buildVersion
        deviceName
        systemVersion
    }

    private static func infoString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}

/// Why the share sheet couldn't be shown.
enum DebugLogShareError: Error {
    /// No active window to present from.
    case noWindow
}

public extension DebugLogDestination {
    /// Shows the system share sheet with the logs, over the debug menu. `.data` logs are written to temporary
    /// files first so they keep their names. The row reports success once the sheet is shown.
    static let shareSheet = DebugLogDestination { logs in
        let urls = try logs.map { log in
            switch log {
            case .file(let url):
                return url
            case .data(let data, let fileName):
                let url = URL.temporaryDirectory.appending(path: fileName)
                try data.write(to: url)
                return url
            }
        }
        try presentShareSheet(urls)
    }
}

@MainActor
private func presentShareSheet(_ urls: [URL]) throws {
    let window = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first
    var presenter = window?.rootViewController
    while let presented = presenter?.presentedViewController {
        presenter = presented
    }
    guard let presenter else {
        throw DebugLogShareError.noWindow
    }
    let controller = UIActivityViewController(activityItems: urls, applicationActivities: nil)
    // iPad shows the share sheet as a popover, which needs an anchor.
    controller.popoverPresentationController?.sourceView = presenter.view
    // sourceRect is in sourceView's own coordinates, so use its bounds, not its frame-relative center.
    let bounds = presenter.view.bounds
    controller.popoverPresentationController?.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
    controller.popoverPresentationController?.permittedArrowDirections = []
    presenter.present(controller, animated: true)
}
#endif
