import AppKit
import Darwin
import Foundation

/// Keeps Sparkle out of states where macOS cannot replace the running bundle:
/// a mounted DMG, Downloads quarantine/App Translocation, or another temporary
/// location. In those cases we offer to move Kabigon to /Applications first.
@MainActor
enum InstallLocationController {
    private static let skipEnvironmentKey = "KABIGON_SKIP_INSTALL_LOCATION_CHECK"

    static var canInstallUpdates: Bool {
        guard isAppBundle else { return true }
        return isRunningFromApplications && !isRunningFromReadOnlyVolume && !isAppTranslocated
    }

    /// Returns true when the current process is being replaced and launch
    /// should stop.
    static func moveToApplicationsIfNeeded() -> Bool {
        guard shouldPromptForMove else { return false }

        let alert = NSAlert()
        alert.messageText = "Move Kabigon to Applications?"
        alert.informativeText = """
        Kabigon needs to run from your Applications folder before it can install updates. Move it there now and relaunch?
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Move and Relaunch")
        alert.addButton(withTitle: "Continue Here")

        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        do {
            try moveCurrentAppToApplicationsAndRelaunch()
            NSApplication.shared.terminate(nil)
            return true
        } catch {
            showMoveFailedAlert(error)
            return false
        }
    }

    static func showUpdatesUnavailableAlert() {
        let alert = NSAlert()
        alert.messageText = "Kabigon needs to be in Applications to update"
        alert.informativeText = """
        Quit Kabigon, move it into your Applications folder, relaunch it from there, and try updates again.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static var shouldPromptForMove: Bool {
        guard isAppBundle else { return false }
        guard ProcessInfo.processInfo.environment[skipEnvironmentKey] == nil else { return false }
        return !canInstallUpdates
    }

    private static var isAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    private static var appURL: URL {
        Bundle.main.bundleURL.standardizedFileURL
    }

    private static var isRunningFromApplications: Bool {
        let path = appURL.path
        return path == "/Applications/Kabigon.app"
            || path.hasPrefix("/Applications/")
            || path.hasPrefix("/Users/") && path.contains("/Applications/")
    }

    private static var isAppTranslocated: Bool {
        appURL.path.contains("/AppTranslocation/")
    }

    private static var isRunningFromReadOnlyVolume: Bool {
        (try? appURL.resourceValues(forKeys: [.volumeIsReadOnlyKey]).volumeIsReadOnly) ?? false
    }

    private static func moveCurrentAppToApplicationsAndRelaunch() throws {
        let fileManager = FileManager.default
        let destination = URL(fileURLWithPath: "/Applications")
            .appendingPathComponent(appURL.lastPathComponent)

        if fileManager.fileExists(atPath: destination.path) {
            var trashedURL: NSURL?
            try fileManager.trashItem(at: destination, resultingItemURL: &trashedURL)
        }

        try fileManager.copyItem(at: appURL, to: destination)
        clearQuarantineAttribute(in: destination)
        NSWorkspace.shared.open(destination)
    }

    private static func clearQuarantineAttribute(in bundleURL: URL) {
        let fileManager = FileManager.default
        var urls = [bundleURL]
        if let enumerator = fileManager.enumerator(at: bundleURL,
                                                   includingPropertiesForKeys: nil,
                                                   options: [],
                                                   errorHandler: nil) {
            urls.append(contentsOf: enumerator.compactMap { $0 as? URL })
        }

        for url in urls {
            _ = url.path.withCString { path in
                removexattr(path, "com.apple.quarantine", XATTR_NOFOLLOW)
            }
        }
    }

    private static func showMoveFailedAlert(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "Kabigon could not be moved"
        alert.informativeText = """
        Move Kabigon to your Applications folder manually, relaunch it from there, and try updates again.
        """
        alert.runModal()
    }
}
