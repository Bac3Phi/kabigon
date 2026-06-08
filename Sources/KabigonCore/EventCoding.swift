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
    public static var baseDir: String { NSHomeDirectory() + "/.kabigon" }
    public static var socketPath: String { baseDir + "/kabigon.sock" }
    public static var queueDir: String { baseDir + "/queue" }

    /// Moves pre-rename data into the Kabigon directory on first launch.
    public static func migrateLegacyDataIfNeeded() {
        let fm = FileManager.default
        let legacy = NSHomeDirectory() + "/.agentpet"
        guard !fm.fileExists(atPath: baseDir), fm.fileExists(atPath: legacy) else { return }
        try? fm.moveItem(atPath: legacy, toPath: baseDir)
    }
}
