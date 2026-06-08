import Foundation

public enum EvolutionMethod: String, Sendable, Equatable {
    case level
    case stone
    case trade
}

/// One practical evolution rule for Kabigon. Canonical level evolutions retain
/// their original threshold; item and trade evolutions use game-friendly level
/// thresholds because Kabigon has no inventory or trading system.
public struct EvolutionRule: Sendable, Equatable {
    public let fromDex: Int
    public let toDex: Int
    public let level: Int
    public let method: EvolutionMethod

    public init(fromDex: Int, toDex: Int, level: Int, method: EvolutionMethod) {
        self.fromDex = fromDex
        self.toDex = toDex
        self.level = level
        self.method = method
    }
}

public enum Gen1EvolutionCatalog {
    private static let stoneLevel = 30
    private static let tradeLevel = 36

    public static let rules: [EvolutionRule] = [
        level(1, 2, 16), level(2, 3, 32),
        level(4, 5, 16), level(5, 6, 36),
        level(7, 8, 16), level(8, 9, 36),
        level(10, 11, 7), level(11, 12, 10),
        level(13, 14, 7), level(14, 15, 10),
        level(16, 17, 18), level(17, 18, 36),
        level(19, 20, 20), level(21, 22, 20), level(23, 24, 22),
        stone(25, 26), level(27, 28, 22),
        level(29, 30, 16), stone(30, 31),
        level(32, 33, 16), stone(33, 34),
        stone(35, 36), stone(37, 38), stone(39, 40),
        level(41, 42, 22), level(43, 44, 21), stone(44, 45),
        level(46, 47, 24), level(48, 49, 31), level(50, 51, 26),
        level(52, 53, 28), level(54, 55, 33), level(56, 57, 28),
        stone(58, 59), level(60, 61, 25), stone(61, 62),
        level(63, 64, 16), trade(64, 65),
        level(66, 67, 28), trade(67, 68),
        level(69, 70, 21), stone(70, 71),
        level(72, 73, 30), level(74, 75, 25), trade(75, 76),
        level(77, 78, 40), level(79, 80, 37), level(81, 82, 30),
        level(84, 85, 31), level(86, 87, 34), level(88, 89, 38),
        stone(90, 91), level(92, 93, 25), trade(93, 94),
        level(96, 97, 26), level(98, 99, 28), level(100, 101, 30),
        stone(102, 103), level(104, 105, 28), level(109, 110, 35),
        level(111, 112, 42), level(116, 117, 32), level(118, 119, 33),
        stone(120, 121), level(129, 130, 20),
        stone(133, 134), stone(133, 135), stone(133, 136),
        level(138, 139, 40), level(140, 141, 40),
        level(147, 148, 30), level(148, 149, 55),
    ]

    public static func evolutions(from dex: Int) -> [EvolutionRule] {
        rules.filter { $0.fromDex == dex }.sorted { $0.toDex < $1.toDex }
    }

    private static func level(_ from: Int, _ to: Int, _ level: Int) -> EvolutionRule {
        EvolutionRule(fromDex: from, toDex: to, level: level, method: .level)
    }

    private static func stone(_ from: Int, _ to: Int) -> EvolutionRule {
        EvolutionRule(fromDex: from, toDex: to, level: stoneLevel, method: .stone)
    }

    private static func trade(_ from: Int, _ to: Int) -> EvolutionRule {
        EvolutionRule(fromDex: from, toDex: to, level: tradeLevel, method: .trade)
    }
}
