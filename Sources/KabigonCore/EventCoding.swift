import Foundation

/// Shared JSON coders so the CLI helper and the daemon agree on the wire
/// format (notably the date strategy).
public enum EventCoding {
    public static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    public static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()
}

/// Default on-disk locations used by both the daemon and the CLI helper.
public enum KabigonPaths {
    public static var baseDir: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return (appSupport ?? URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support"))
            .appendingPathComponent("Kabigon", isDirectory: true)
            .path
    }

    public static var socketPath: String { baseDir + "/kabigon.sock" }
    public static var queueDir: String { baseDir + "/queue" }

    public static var legacyDotDir: String { NSHomeDirectory() + "/.kabigon" }
    public static var legacyAgentPetDir: String { NSHomeDirectory() + "/.agentpet" }

    /// Moves legacy data into Application Support on first launch.
    public static func migrateLegacyDataIfNeeded() {
        let fm = FileManager.default
        let current = baseDir
        guard !fm.fileExists(atPath: current) else { return }
        try? fm.createDirectory(
            atPath: URL(fileURLWithPath: current).deletingLastPathComponent().path,
            withIntermediateDirectories: true
        )

        if fm.fileExists(atPath: legacyDotDir) {
            try? fm.moveItem(atPath: legacyDotDir, toPath: current)
            return
        }

        if fm.fileExists(atPath: legacyAgentPetDir) {
            try? fm.moveItem(atPath: legacyAgentPetDir, toPath: current)
        }
    }
}
