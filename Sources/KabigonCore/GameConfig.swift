import Foundation

/// Tunable gameplay numbers (XP rewards, leveling curve, evolution thresholds).
/// Defaults ship in code; power users can override any field with a JSON file at
/// `~/.kabigon/gameconfig.json`. This is intentionally not surfaced in the UI.
public struct GameConfig: Codable, Sendable, Equatable {
    /// XP granted each time an agent finishes a turn (chatting with it).
    public var xpPerDone: Int
    /// XP granted when a session that needed input gets unblocked.
    public var xpPerWaitingResolved: Int
    /// Affection granted per manual pet/cuddle.
    public var affectionPerPet: Int
    /// Minimum seconds between affection gains from petting.
    public var petCooldownSeconds: Double
    /// XP needed to go from level L to L+1 is `xpBasePerLevel * L`.
    public var xpBasePerLevel: Int
    public var maxLevel: Int
    /// When true, use each species' canonical evolution level. When false, use
    /// `evolveLevelOverride` (index 0 = stage 0→1, index 1 = stage 1→2).
    public var useSpeciesEvolveLevels: Bool
    public var evolveLevelOverride: [Int]?

    public static let `default` = GameConfig(
        xpPerDone: 10,
        xpPerWaitingResolved: 5,
        affectionPerPet: 1,
        petCooldownSeconds: 30,
        xpBasePerLevel: 20,
        maxLevel: 100,
        useSpeciesEvolveLevels: true,
        evolveLevelOverride: nil
    )

    // MARK: Leveling math

    /// Cumulative XP required to reach `level` (level 1 == 0 XP).
    public func totalXP(forLevel level: Int) -> Int {
        let n = max(level, 1) - 1
        return xpBasePerLevel * n * (n + 1) / 2
    }

    /// The level reached for a given total XP, capped at `maxLevel`.
    public func level(forTotalXP xp: Int) -> Int {
        var level = 1
        while level < maxLevel && xp >= totalXP(forLevel: level + 1) { level += 1 }
        return level
    }

    /// XP accumulated within the current level (for a progress bar).
    public func xpIntoLevel(totalXP xp: Int) -> Int {
        xp - totalXP(forLevel: level(forTotalXP: xp))
    }

    /// XP span of the current level (0 at max level).
    public func xpForLevelSpan(totalXP xp: Int) -> Int {
        let level = self.level(forTotalXP: xp)
        guard level < maxLevel else { return 0 }
        return totalXP(forLevel: level + 1) - totalXP(forLevel: level)
    }

    /// Effective evolution level for a stage, honouring the override flag.
    public func evolveLevel(forStage stage: Int, default canonical: Int?) -> Int? {
        guard !useSpeciesEvolveLevels, let override = evolveLevelOverride else { return canonical }
        return stage < override.count ? override[stage] : canonical
    }

    /// Loads the config, layering a JSON override file over the defaults. Any
    /// missing/invalid fields fall back to the default value.
    public static func load(directory: String = KabigonPaths.baseDir) -> GameConfig {
        let url = URL(fileURLWithPath: directory).appendingPathComponent("gameconfig.json")
        guard let data = try? Data(contentsOf: url) else { return .default }
        return (try? JSONDecoder().decode(GameConfig.self, from: data)) ?? .default
    }
}
