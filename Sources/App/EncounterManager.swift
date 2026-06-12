import Foundation
import KabigonCore

/// Spawns wild Pokémon over time: every so often an uncaught supported species
/// "appears", its assets are downloaded on the spot, and it is added to the
/// Pokédex flagged NEW (with a notification) so the collection grows as you work.
@MainActor
final class EncounterManager: ObservableObject {
    static let shared = EncounterManager()

    /// Average seconds between wild encounters; each wait is jittered ±50%.
    private let baseInterval: TimeInterval = 25 * 60
    private let shinyOdds = 64
    private var timer: Timer?
    @Published private(set) var isSpawning = false

    /// Starts the background encounter timer.
    func start() {
        // A short first wait so a brand-new player sees the system come alive.
        scheduleNext(after: 30)
    }

    /// Manually triggers a random encounter immediately.
    func triggerRandomEncounter() {
        Task { @MainActor in await spawn(forceShiny: false) }
    }

    /// Testing helper: immediately grants a shiny basic-form Pokémon.
    func triggerShinyEncounter() {
        Task { @MainActor in await spawn(forceShiny: true) }
    }

    private func scheduleNext(after seconds: TimeInterval? = nil) {
        timer?.invalidate()
        let wait = seconds ?? baseInterval * Double.random(in: 0.5...1.5)
        timer = Timer.scheduledTimer(withTimeInterval: wait, repeats: false) { _ in
            Task { @MainActor [weak self] in await self?.spawn(forceShiny: false) }
        }
    }

    /// Picks a random uncaught species, downloads it, and records the catch.
    private func spawn(forceShiny: Bool) async {
        // Ensure we don't have two timers running if this was triggered manually.
        timer?.invalidate()
        defer { scheduleNext() }
        guard ProgressStore.shared.hasChosenStarter, !isSpawning else { return }
        isSpawning = true
        defer { isSpawning = false }
        let caught = Set(PokedexStore.shared.data.entries.map(\.dex))
        let uncaught = PokemonEvolutionCatalog.receivableDexes.filter { !caught.contains($0) }
        let pool = uncaught.isEmpty && forceShiny
            ? PokemonEvolutionCatalog.receivableDexes
            : uncaught
        guard var dex = pool.randomElement() else { return }   // Pokédex complete

        await PMDPetStore.shared.ensureLoaded(dex: dex)
        // A test encounter must always produce a shiny, even when the randomly
        // selected species cannot be downloaded while offline.
        if forceShiny, !PMDPetStore.shared.isAvailable(dex: dex) {
            dex = ProgressStore.shared.displayDex
            await PMDPetStore.shared.ensureLoaded(dex: dex)
        }
        // Normal encounters skip unavailable species and retry on a later timer.
        guard PMDPetStore.shared.isAvailable(dex: dex) else { return }

        let level = 1
        let isShiny = forceShiny || Int.random(in: 1...shinyOdds) == 1
        PokedexStore.shared.register(dex: dex, level: level, isShiny: isShiny, isNew: true)
        let name = PokemonPokedex.name(for: dex) ?? "A wild Pokémon"
        let displayName = isShiny ? "Shiny \(name)" : name
        PetController.shared.reactToEncounter(name: displayName, level: level)
        NotificationManager.shared.notify(
            title: "A wild \(displayName) appeared!",
            body: "Lv \(level) · added to your Pokédex")
    }
}
