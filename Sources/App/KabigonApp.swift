import SwiftUI
import AppKit
import KabigonCore

struct KabigonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The UI lives in a status-item popover and floating windows managed by
        // AppDelegate; this empty scene just satisfies the App protocol.
        Settings { EmptyView() }
    }
}

/// Runs the app as a menu bar accessory (no Dock icon) and boots the daemon.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard !InstallLocationController.moveToApplicationsIfNeeded() else { return }
        // Pre-load the three Kanto starter species so the onboarding picker
        // and the floating pet are ready immediately.
        PMDCatalog.starterDexes.forEach { PMDPetStore.shared.preload($0) }
        // Also pre-load the player's active display Pokémon (may be wild or evolved).
        PMDPetStore.shared.preload(ProgressStore.shared.displayDex)
        PetController.shared.start()
        PetWindowController.shared.start()
        AppDaemon.shared.start()
        // Make sure the player's active Pokémon is in the Pokédex, then let wild
        // Pokémon start appearing over time.
        ProgressStore.shared.syncStarterToPokedex()
        ProgressStore.shared.startAutoSwitch()
        EncounterManager.shared.start()
        SettingsModel.shared.migrateInstalledHooksIfNeeded()
        ReminderStore.shared.start()
        _ = UpdaterController.shared
        StatusBarController.shared.start()
        SettingsWindowController.shared.showOnFirstLaunch()
    }
}
