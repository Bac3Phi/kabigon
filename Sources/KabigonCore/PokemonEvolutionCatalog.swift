import Foundation

public enum PokemonEvolutionCatalog {
    private static let friendshipLevel = 30

    public static let rules: [EvolutionRule] = Gen1EvolutionCatalog.rules + [
        level(152, 153, 16), level(153, 154, 32),
        level(155, 156, 14), level(156, 157, 36),
        level(158, 159, 18), level(159, 160, 30),
        level(161, 162, 15), level(163, 164, 20),
        level(165, 166, 18), level(167, 168, 22),
        friendship(42, 169), level(170, 171, 27),
        friendship(172, 25), friendship(173, 35), friendship(174, 39),
        friendship(175, 176), level(177, 178, 25),
        level(179, 180, 15), level(180, 181, 30),
        stone(44, 182), level(183, 184, 18), trade(61, 186),
        level(187, 188, 18), level(188, 189, 27),
        stone(191, 192), level(194, 195, 20),
        friendship(133, 196), friendship(133, 197), trade(79, 199),
        level(204, 205, 31), trade(95, 208),
        level(209, 210, 23), trade(123, 212),
        level(216, 217, 30), level(218, 219, 38),
        level(220, 221, 33), level(223, 224, 25),
        level(228, 229, 24), trade(117, 230),
        level(231, 232, 25), trade(137, 233),
        level(236, 106, 20), level(236, 107, 20), level(236, 237, 20),
        level(238, 124, 30), level(239, 125, 30), level(240, 126, 30),
        friendship(113, 242), level(246, 247, 30), level(247, 248, 55),
    ]

    public static func evolutions(from dex: Int) -> [EvolutionRule] {
        rules.filter { $0.fromDex == dex }.sorted { $0.toDex < $1.toDex }
    }

    /// Species that may be received as new wild Pokémon: only first/basic forms
    /// in their evolution family. Multi-branch basics such as Eevee stay
    /// eligible because nothing evolves into them.
    public static let receivableDexes: [Int] = {
        let evolvedDexes = Set(rules.map(\.toDex))
        return PokemonPokedex.dexRange.filter { !evolvedDexes.contains($0) }
    }()

    public static func isReceivable(_ dex: Int) -> Bool {
        receivableDexes.contains(dex)
    }

    private static func level(_ from: Int, _ to: Int, _ level: Int) -> EvolutionRule {
        EvolutionRule(fromDex: from, toDex: to, level: level, method: .level)
    }

    private static func stone(_ from: Int, _ to: Int) -> EvolutionRule {
        EvolutionRule(fromDex: from, toDex: to, level: 30, method: .stone)
    }

    private static func trade(_ from: Int, _ to: Int) -> EvolutionRule {
        EvolutionRule(fromDex: from, toDex: to, level: 36, method: .trade)
    }

    private static func friendship(_ from: Int, _ to: Int) -> EvolutionRule {
        EvolutionRule(fromDex: from, toDex: to, level: friendshipLevel, method: .level)
    }
}
