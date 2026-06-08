import Foundation

/// One Pokémon form in a starter evolution line. `evolveLevel`/`nextDex` are the
/// canonical thresholds; the game config can override them at runtime.
public struct PMDSpecies: Sendable, Equatable, Identifiable {
    public let dex: Int
    public let name: String
    /// Evolution stage within its line: 0 (basic), 1, or 2 (final).
    public let stage: Int
    /// National-dex number of the line's first form (its starter id).
    public let lineRoot: Int
    /// Default level required to evolve into `nextDex` (nil for final forms).
    public let evolveLevel: Int?
    public let nextDex: Int?

    public var id: Int { dex }
    /// Folder name under Resources/pmd (zero-padded dex).
    public var assetSlug: String { String(format: "%04d", dex) }
}

/// The bundled Kanto starter lines (national dex 0001–0009) with canonical
/// evolution levels.
public enum PMDCatalog {
    public static let species: [PMDSpecies] = [
        PMDSpecies(dex: 1, name: "Bulbasaur",  stage: 0, lineRoot: 1, evolveLevel: 16, nextDex: 2),
        PMDSpecies(dex: 2, name: "Ivysaur",    stage: 1, lineRoot: 1, evolveLevel: 32, nextDex: 3),
        PMDSpecies(dex: 3, name: "Venusaur",   stage: 2, lineRoot: 1, evolveLevel: nil, nextDex: nil),
        PMDSpecies(dex: 4, name: "Charmander", stage: 0, lineRoot: 4, evolveLevel: 16, nextDex: 5),
        PMDSpecies(dex: 5, name: "Charmeleon", stage: 1, lineRoot: 4, evolveLevel: 36, nextDex: 6),
        PMDSpecies(dex: 6, name: "Charizard",  stage: 2, lineRoot: 4, evolveLevel: nil, nextDex: nil),
        PMDSpecies(dex: 7, name: "Squirtle",   stage: 0, lineRoot: 7, evolveLevel: 16, nextDex: 8),
        PMDSpecies(dex: 8, name: "Wartortle",  stage: 1, lineRoot: 7, evolveLevel: 36, nextDex: 9),
        PMDSpecies(dex: 9, name: "Blastoise",  stage: 2, lineRoot: 7, evolveLevel: nil, nextDex: nil),
    ]

    /// The three canonical starters (basic forms).
    public static let starterDexes = [1, 4, 7]

    /// Every bundled species in dex order — the full set the player can pick from.
    public static let allDexes = species.map(\.dex)

    /// Whether a dex is the basic form (root) of an evolution line, which keeps
    /// evolving as it levels up. Non-root picks stay a fixed form.
    public static func isLineRoot(_ dex: Int) -> Bool {
        species(dex: dex).map { $0.stage == 0 } ?? false
    }

    public static func species(dex: Int) -> PMDSpecies? {
        species.first { $0.dex == dex }
    }

    /// The full evolution chain for a line, ordered basic → final.
    public static func line(root: Int) -> [PMDSpecies] {
        species.filter { $0.lineRoot == root }.sorted { $0.stage < $1.stage }
    }

    /// Resolves which form a line is in at a given level, applying any config
    /// override of the per-stage evolution levels.
    public static func form(lineRoot: Int, level: Int, config: GameConfig) -> PMDSpecies {
        let chain = line(root: lineRoot)
        guard var current = chain.first else {
            return species(dex: lineRoot) ?? species[0]
        }
        for (offset, form) in chain.enumerated() {
            let threshold = config.evolveLevel(forStage: form.stage, default: form.evolveLevel)
            guard let threshold, let next = form.nextDex,
                  let nextForm = species(dex: next), level >= threshold else { break }
            current = nextForm
            _ = offset
        }
        return current
    }
}
