import Foundation
import KabigonCore

/// Owns the player's Pokédex: which Gen-1 species have been caught, each one's
/// level, and the NEW flag for freshly discovered species. Persists to
/// `~/.kabigon/pokedex.json` so collection progress survives across launches.
@MainActor
final class PokedexStore: ObservableObject {
    static let shared = PokedexStore()

    @Published private(set) var data: PokedexData

    init() { data = PokedexData.load() }

    func isCaught(_ dex: Int) -> Bool { data.isCaught(dex) }
    func entry(_ dex: Int) -> PokedexEntry? { data.entry(dex: dex) }
    var caughtCount: Int { data.caughtCount }
    var newCount: Int { data.newCount }

    /// Records a caught/seen species, or bumps its level if already owned, and
    /// persists the change.
    func register(dex: Int, level: Int, isNew: Bool) {
        guard Gen1Pokedex.dexRange.contains(dex) else { return }
        data.upsert(dex: dex, level: max(level, 1), isNew: isNew)
        data.save()
    }

    /// Clears the NEW flag for one species (e.g. after the player views it).
    func clearNew(dex: Int) {
        guard data.entry(dex: dex)?.isNew == true else { return }
        data.clearNew(dex: dex)
        data.save()
    }

    /// Clears every NEW flag (called when the Pokédex is opened).
    func clearAllNew() {
        guard data.newCount > 0 else { return }
        data.clearAllNew()
        data.save()
    }
}
