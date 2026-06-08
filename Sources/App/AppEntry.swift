import Foundation
import KabigonCore

/// Single binary, two roles:
/// - `kabigon hook ...` runs the lightweight CLI helper (issue #4).
/// - no arguments launches the menu bar app.
@main
struct KabigonMain {
    static func main() {
        KabigonPaths.migrateLegacyDataIfNeeded()
        migrateLegacyDefaultsIfNeeded()
        let args = Array(CommandLine.arguments.dropFirst())
        switch args.first {
        case "hook":
            HookCLI.run(arguments: Array(args.dropFirst()))
        case "run":
            RunCLI.run(arguments: Array(args.dropFirst()))
        default:
            KabigonApp.main()
        }
    }

    private static func migrateLegacyDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        let marker = "kabigon.didMigrateAgentPetDefaults"
        guard !defaults.bool(forKey: marker) else { return }
        if let legacy = defaults.persistentDomain(forName: "com.agentpet.app") {
            for (key, value) in legacy where defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }
        defaults.set(true, forKey: marker)
    }
}
