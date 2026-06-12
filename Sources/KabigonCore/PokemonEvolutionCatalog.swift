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
        level(252, 253, 16), level(253, 254, 36),
        level(255, 256, 16), level(256, 257, 36),
        level(258, 259, 16), level(259, 260, 36),
        level(261, 262, 18), level(263, 264, 20),
        level(265, 266, 7), level(266, 267, 10),
        level(265, 268, 7), level(268, 269, 10),
        level(270, 271, 14), stone(271, 272),
        level(273, 274, 14), stone(274, 275),
        level(276, 277, 22), level(278, 279, 25),
        level(280, 281, 20), level(281, 282, 30),
        level(283, 284, 22), level(285, 286, 23),
        level(287, 288, 18), level(288, 289, 36),
        level(290, 291, 20), level(290, 292, 20),
        level(293, 294, 20), level(294, 295, 40),
        level(296, 297, 24), friendship(298, 183),
        stone(300, 301), level(304, 305, 32), level(305, 306, 42),
        level(307, 308, 37), level(309, 310, 26),
        level(316, 317, 26), level(318, 319, 30),
        level(320, 321, 40), level(322, 323, 33),
        level(325, 326, 32), level(328, 329, 35), level(329, 330, 45),
        level(331, 332, 32), level(333, 334, 35),
        level(339, 340, 30), level(341, 342, 30),
        level(343, 344, 36), level(345, 346, 40), level(347, 348, 40),
        level(349, 350, 30), level(353, 354, 37), level(355, 356, 37),
        friendship(360, 202), level(361, 362, 42),
        level(363, 364, 32), level(364, 365, 44),
        stone(366, 367), stone(366, 368),
        level(371, 372, 30), level(372, 373, 50),
        level(374, 375, 20), level(375, 376, 45),
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
