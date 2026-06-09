import Foundation

/// National Pokédex species supported by Kabigon. The bundled starter lines
/// still ship as local assets; every other species is downloaded on demand.
public enum PokemonPokedex {
    /// National-dex range covered by the collectible Pokédex.
    public static let dexRange = 1...251
    public static var count: Int { names.count }

    public static let gen2Names: [String] = [
        "Chikorita", "Bayleef", "Meganium", "Cyndaquil", "Quilava", "Typhlosion",
        "Totodile", "Croconaw", "Feraligatr", "Sentret", "Furret", "Hoothoot",
        "Noctowl", "Ledyba", "Ledian", "Spinarak", "Ariados", "Crobat",
        "Chinchou", "Lanturn", "Pichu", "Cleffa", "Igglybuff", "Togepi",
        "Togetic", "Natu", "Xatu", "Mareep", "Flaaffy", "Ampharos",
        "Bellossom", "Marill", "Azumarill", "Sudowoodo", "Politoed", "Hoppip",
        "Skiploom", "Jumpluff", "Aipom", "Sunkern", "Sunflora", "Yanma",
        "Wooper", "Quagsire", "Espeon", "Umbreon", "Murkrow", "Slowking",
        "Misdreavus", "Unown", "Wobbuffet", "Girafarig", "Pineco", "Forretress",
        "Dunsparce", "Gligar", "Steelix", "Snubbull", "Granbull", "Qwilfish",
        "Scizor", "Shuckle", "Heracross", "Sneasel", "Teddiursa", "Ursaring",
        "Slugma", "Magcargo", "Swinub", "Piloswine", "Corsola", "Remoraid",
        "Octillery", "Delibird", "Mantine", "Skarmory", "Houndour", "Houndoom",
        "Kingdra", "Phanpy", "Donphan", "Porygon2", "Stantler", "Smeargle",
        "Tyrogue", "Hitmontop", "Smoochum", "Elekid", "Magby", "Miltank",
        "Blissey", "Raikou", "Entei", "Suicune", "Larvitar", "Pupitar",
        "Tyranitar", "Lugia", "Ho-Oh", "Celebi",
    ]

    public static let names = Gen1Pokedex.names + gen2Names

    /// Display name for a national-dex number, or nil if out of range.
    public static func name(for dex: Int) -> String? {
        guard dexRange.contains(dex) else { return nil }
        return names[dex - 1]
    }

    /// Species summary for a national-dex number, or nil when unsupported.
    public static func description(for dex: Int) -> String? {
        if let description = Gen1Pokedex.description(for: dex) { return description }
        return Gen2Pokedex.description(for: dex)
    }
}

public enum Gen2Pokedex {
    public static let dexRange = 152...251
    public static var count: Int { names.count }
    public static let names = PokemonPokedex.gen2Names

    public static func name(for dex: Int) -> String? {
        guard dexRange.contains(dex) else { return nil }
        return names[dex - dexRange.lowerBound]
    }
}
