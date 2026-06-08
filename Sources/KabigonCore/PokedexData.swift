import Foundation

/// One collected Pokémon's saved progress: its national-dex number, the highest
/// level it has reached, whether it is still flagged NEW (freshly added, not yet
/// viewed), and when it was first caught.
public struct PokedexEntry: Codable, Sendable, Equatable, Identifiable {
    public var dex: Int
    public var level: Int
    public var isNew: Bool
    public var caughtAt: Date

    public var id: Int { dex }

    public init(dex: Int, level: Int, isNew: Bool, caughtAt: Date) {
        self.dex = dex
        self.level = level
        self.isNew = isNew
        self.caughtAt = caughtAt
    }
}

/// The player's whole collection, persisted to `~/.kabigon/pokedex.json` so the
/// caught species, their levels, and progress survive across launches.
public struct PokedexData: Codable, Sendable, Equatable {
    public var entries: [PokedexEntry]

    public static let empty = PokedexData(entries: [])

    public init(entries: [PokedexEntry]) { self.entries = entries }

    public func entry(dex: Int) -> PokedexEntry? { entries.first { $0.dex == dex } }
    public func isCaught(_ dex: Int) -> Bool { entry(dex: dex) != nil }
    public var caughtCount: Int { entries.count }
    public var newCount: Int { entries.lazy.filter { $0.isNew }.count }

    /// Inserts a new entry or updates an existing one, keeping the highest level
    /// seen and preserving the original caught date.
    public mutating func upsert(dex: Int, level: Int, isNew: Bool, now: Date = Date()) {
        if let i = entries.firstIndex(where: { $0.dex == dex }) {
            entries[i].level = max(entries[i].level, level)
            if isNew { entries[i].isNew = true }
        } else {
            entries.append(PokedexEntry(dex: dex, level: level, isNew: isNew, caughtAt: now))
        }
    }

    public mutating func clearNew(dex: Int) {
        if let i = entries.firstIndex(where: { $0.dex == dex }) { entries[i].isNew = false }
    }

    public mutating func clearAllNew() {
        for i in entries.indices { entries[i].isNew = false }
    }

    // MARK: Persistence

    public static func fileURL(directory: String = KabigonPaths.baseDir) -> URL {
        URL(fileURLWithPath: directory).appendingPathComponent("pokedex.json")
    }

    public static func load(directory: String = KabigonPaths.baseDir) -> PokedexData {
        guard let data = try? Data(contentsOf: fileURL(directory: directory)),
              let decoded = try? EventCoding.decoder.decode(PokedexData.self, from: data)
        else { return .empty }
        return decoded
    }

    public func save(directory: String = KabigonPaths.baseDir) {
        try? FileManager.default.createDirectory(
            atPath: directory, withIntermediateDirectories: true)
        guard let data = try? EventCoding.encoder.encode(self) else { return }
        try? data.write(to: Self.fileURL(directory: directory))
    }
}
