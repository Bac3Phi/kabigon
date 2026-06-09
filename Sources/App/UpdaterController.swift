import AppKit
import Sparkle

/// Owns the Sparkle updater: background checks against the appcast feed
/// (configured via SUFeedURL / SUPublicEDKey in Info.plist) plus a manual
/// "Check for Updates…" entry point from the menu bar.
@MainActor
final class UpdaterController: NSObject, ObservableObject {
    static let shared = UpdaterController()

    private let controller: SPUStandardUpdaterController

    override init() {
        // Only start Sparkle when the running bundle can be replaced. Otherwise
        // Sparkle shows its own translocation/DMG error during update checks.
        controller = SPUStandardUpdaterController(startingUpdater: InstallLocationController.canInstallUpdates,
                                                  updaterDelegate: nil,
                                                  userDriverDelegate: nil)
        super.init()
    }

    /// User-initiated check (shows "you're up to date" if nothing is newer).
    func checkForUpdates() {
        guard InstallLocationController.canInstallUpdates else {
            InstallLocationController.showUpdatesUnavailableAlert()
            return
        }
        controller.updater.checkForUpdates()
    }
}
