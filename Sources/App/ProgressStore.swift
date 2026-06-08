import Foundation
import KabigonCore

struct PetLevelUpEvent: Equatable {
    let dex: Int
    let level: Int
}

struct PokemonEvolutionEvent: Equatable {
    let dex: Int
    let name: String
}

/// Owns the player's progression: chosen starter line, total XP (earned by
/// chatting with agents), affection (earned by petting), and the derived level
/// and current evolved form. Persists to UserDefaults.
@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var hasChosenStarter: Bool
    @Published private(set) var starterDex: Int
    /// The Pokémon actually displayed on screen. Defaults to the current evolved
    /// form of the starter line, but the player can switch it to any caught Pokémon
    /// (wild or starter).
    @Published private(set) var displayDex: Int
    /// XP is tracked per species so every caught Pokémon levels independently.
    @Published private(set) var pokemonXP: [Int: Int]
    @Published private(set) var affection: Int
    @Published var levelUpEvent: PetLevelUpEvent?
    /// Set briefly when an evolution happens so the UI can celebrate it.
    @Published var justEvolvedTo: PokemonEvolutionEvent?

    let config: GameConfig

    private var lastPetAt: Date = .distantPast

    private static let chosenKey  = "agentpet.hasChosenStarter"
    private static let starterKey = "agentpet.starterDex"
    private static let displayKey = "agentpet.displayDex"
    private static let xpKey      = "agentpet.totalXP"
    private static let pokemonXPKey = "agentpet.pokemonXP"
    private static let affectionKey = "agentpet.affection"

    init() {
        let d = UserDefaults.standard
        config = GameConfig.load()
        hasChosenStarter = d.bool(forKey: Self.chosenKey)
        let starter = d.object(forKey: Self.starterKey) as? Int ?? PMDCatalog.starterDexes[0]
        starterDex = starter
        if let data = d.data(forKey: Self.pokemonXPKey),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            pokemonXP = decoded
        } else {
            pokemonXP = [:]
        }
        affection = d.integer(forKey: Self.affectionKey)
        let legacyXP = d.integer(forKey: Self.xpKey)
        let legacyLevel = config.level(forTotalXP: legacyXP)
        let legacyForm = PMDCatalog.form(lineRoot: starter, level: legacyLevel, config: config).dex
        displayDex = (d.object(forKey: Self.displayKey) as? Int) ?? legacyForm

        migrateLegacyProgressIfNeeded(legacyXP: legacyXP, starter: starter)
        seedXPFromPokedex()
        PMDPetStore.shared.preload(displayDex)
    }

    // MARK: Derived

    var totalXP: Int { xp(for: displayDex) }
    var level: Int { level(for: displayDex) }

    /// Display name for the active Pokémon (wild or starter).
    var displayName: String {
        Gen1Pokedex.name(for: displayDex) ?? "Pokémon #\(displayDex)"
    }

    var displayLevel: Int { level }

    /// Fractional progress (0–1) through the current level.
    var levelProgress: Double {
        let span = config.xpForLevelSpan(totalXP: totalXP)
        guard span > 0 else { return 1 }
        return min(1, Double(config.xpIntoLevel(totalXP: totalXP)) / Double(span))
    }

    var xpIntoLevel: Int { config.xpIntoLevel(totalXP: totalXP) }
    var xpForLevelSpan: Int { config.xpForLevelSpan(totalXP: totalXP) }

    /// The level at which the current form evolves next (nil for final forms).
    var nextEvolutionLevel: Int? {
        Gen1EvolutionCatalog.evolutions(from: displayDex)
            .filter { !PokedexStore.shared.isCaught($0.toDex) }
            .map(effectiveEvolutionLevel)
            .min()
    }

    // MARK: Mutations

    func chooseStarter(_ dex: Int) {
        guard PMDCatalog.starterDexes.contains(dex) else { return }
        starterDex = dex
        hasChosenStarter = true
        let d = UserDefaults.standard
        d.set(dex, forKey: Self.starterKey)
        d.set(true, forKey: Self.chosenKey)
        if pokemonXP[dex] == nil { pokemonXP[dex] = 0 }
        savePokemonXP()
        displayDex = dex
        d.set(displayDex, forKey: Self.displayKey)
        PMDPetStore.shared.preload(dex)
        PokedexStore.shared.register(dex: dex, level: level(for: dex), isNew: false)
    }

    /// Switches to any caught species or unlocked evolution form. Selecting an
    /// older form does not discard later forms or their independent progress.
    func choosePokemon(dex: Int) {
        guard PokedexStore.shared.isCaught(dex) else { return }
        seedXPIfNeeded(for: dex)
        displayDex = dex
        UserDefaults.standard.set(dex, forKey: Self.displayKey)
        PMDPetStore.shared.preload(dex)
    }

    /// Awards XP to the active Pokémon and unlocks its next evolution when the
    /// species-specific threshold is reached.
    func addXP(_ amount: Int) {
        guard amount > 0, hasChosenStarter else { return }
        let dex = displayDex
        seedXPIfNeeded(for: dex)
        let oldLevel = level(for: dex)
        pokemonXP[dex, default: 0] += amount
        savePokemonXP()
        let newLevel = level(for: dex)
        PokedexStore.shared.register(dex: dex, level: newLevel, isNew: false)
        if newLevel > oldLevel {
            levelUpEvent = PetLevelUpEvent(dex: dex, level: newLevel)
        }
        applyEvolutionIfNeeded(from: dex, level: newLevel)
    }

    /// Test helper for development: grants exactly enough XP to reach the next
    /// level, which also exercises evolution thresholds naturally.
    func levelUpForTesting() {
        guard hasChosenStarter, level < config.maxLevel else { return }
        let nextLevelXP = config.totalXP(forLevel: level + 1)
        addXP(max(1, nextLevelXP - totalXP))
    }

    /// Records the player's current form in the Pokédex (e.g. at launch, so an
    /// existing save's active Pokémon always counts as caught).
    func syncStarterToPokedex() {
        guard hasChosenStarter else { return }
        PokedexStore.shared.register(dex: displayDex, level: level, isNew: false)
    }

    /// Manual pet/cuddle. Returns true if affection was granted (not on cooldown).
    @discardableResult
    func pet(now: Date = Date()) -> Bool {
        guard hasChosenStarter else { return false }
        guard now.timeIntervalSince(lastPetAt) >= config.petCooldownSeconds else { return false }
        lastPetAt = now
        affection += config.affectionPerPet
        UserDefaults.standard.set(affection, forKey: Self.affectionKey)
        return true
    }

    func level(for dex: Int) -> Int {
        config.level(forTotalXP: xp(for: dex))
    }

    private func xp(for dex: Int) -> Int {
        if let saved = pokemonXP[dex] { return saved }
        let caughtLevel = PokedexStore.shared.entry(dex)?.level ?? 1
        return config.totalXP(forLevel: caughtLevel)
    }

    private func seedXPIfNeeded(for dex: Int) {
        guard pokemonXP[dex] == nil else { return }
        pokemonXP[dex] = xp(for: dex)
        savePokemonXP()
    }

    private func seedXPFromPokedex() {
        var changed = false
        for entry in PokedexStore.shared.data.entries where pokemonXP[entry.dex] == nil {
            pokemonXP[entry.dex] = config.totalXP(forLevel: entry.level)
            changed = true
        }
        if changed { savePokemonXP() }
    }

    private func migrateLegacyProgressIfNeeded(legacyXP: Int, starter: Int) {
        guard pokemonXP.isEmpty, hasChosenStarter else { return }
        pokemonXP[starter] = legacyXP
        let legacyLevel = config.level(forTotalXP: legacyXP)
        for form in PMDCatalog.line(root: starter) {
            let unlockLevel = form.stage == 0
                ? 1
                : config.evolveLevel(
                    forStage: form.stage - 1,
                    default: PMDCatalog.line(root: starter)[form.stage - 1].evolveLevel
                ) ?? config.maxLevel + 1
            guard legacyLevel >= unlockLevel else { continue }
            pokemonXP[form.dex] = legacyXP
            PokedexStore.shared.register(dex: form.dex, level: legacyLevel, isNew: false)
        }
        savePokemonXP()
    }

    private func savePokemonXP() {
        guard let data = try? JSONEncoder().encode(pokemonXP) else { return }
        UserDefaults.standard.set(data, forKey: Self.pokemonXPKey)
    }

    private func applyEvolutionIfNeeded(from dex: Int, level: Int) {
        let unlocked = Gen1EvolutionCatalog.evolutions(from: dex).filter {
            level >= effectiveEvolutionLevel($0) && !PokedexStore.shared.isCaught($0.toDex)
        }
        guard !unlocked.isEmpty else { return }

        for rule in unlocked {
            pokemonXP[rule.toDex] = max(
                pokemonXP[rule.toDex] ?? 0,
                config.totalXP(forLevel: level)
            )
            PokedexStore.shared.register(dex: rule.toDex, level: level, isNew: true)
        }
        savePokemonXP()

        guard let primary = unlocked.first else { return }
        let nextDex = primary.toDex
        let name = Gen1Pokedex.name(for: nextDex) ?? "Pokémon #\(nextDex)"
        Task { @MainActor in
            await PMDPetStore.shared.ensureLoaded(dex: nextDex)
            guard PMDPetStore.shared.isAvailable(dex: nextDex) else { return }
            if displayDex == dex {
                displayDex = nextDex
                UserDefaults.standard.set(nextDex, forKey: Self.displayKey)
            }
            justEvolvedTo = PokemonEvolutionEvent(dex: nextDex, name: name)
        }
    }

    private func effectiveEvolutionLevel(_ rule: EvolutionRule) -> Int {
        guard let starterForm = PMDCatalog.species(dex: rule.fromDex) else { return rule.level }
        return config.evolveLevel(forStage: starterForm.stage, default: rule.level) ?? rule.level
    }
}
