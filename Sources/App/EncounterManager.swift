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
    private var timer: Timer?

    /// Starts the background encounter timer.
    func start() {
        // A short first wait so a brand-new player sees the system come alive.
        scheduleNext(after: 30)
    }

    /// Manually triggers a random encounter immediately.
    func triggerRandomEncounter() {
        Task { @MainActor in await spawn() }
    }

    private func scheduleNext(after seconds: TimeInterval? = nil) {
        timer?.invalidate()
        let wait = seconds ?? (15 * 60) * Double.random(in: 0.5...1.5)
        timer = Timer.scheduledTimer(withTimeInterval: wait, repeats: false) { _ in
            Task { @MainActor [weak self] in await self?.spawn() }
        }
    }

    /// Picks a random uncaught species, downloads it, and records the catch.
    private func spawn() async {
        // Ensure we don't have two timers running if this was triggered manually.
        timer?.invalidate()
        defer { scheduleNext() }
        guard ProgressStore.shared.hasChosenStarter else { return }
        let caught = Set(PokedexStore.shared.data.entries.map(\.dex))
        let pool = PokemonEvolutionCatalog.receivableDexes.filter { !caught.contains($0) }
        guard let dex = pool.randomElement() else { return }   // Pokédex complete

        await PMDPetStore.shared.ensureLoaded(dex: dex)
        // If the download failed (offline, missing sprite), skip; we retry later.
        guard PMDPetStore.shared.isAvailable(dex: dex) else { return }

        let level = 1
        PokedexStore.shared.register(dex: dex, level: level, isNew: true)
        let name = PokemonPokedex.name(for: dex) ?? "A wild Pokémon"
        PetController.shared.reactToEncounter(name: name, level: level)
        NotificationManager.shared.notify(
            title: "A wild \(name) appeared!",
            body: "Lv \(level) · added to your Pokédex")
    }
}
