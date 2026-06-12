import Foundation

/// National Pokédex species supported by Kabigon. The bundled starter lines
/// still ship as local assets; every other species is downloaded on demand.
public enum PokemonPokedex {
    /// National-dex range covered by the collectible Pokédex.
    public static let dexRange = 1...493
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

    public static let gen3Names: [String] = [
        "Treecko", "Grovyle", "Sceptile", "Torchic", "Combusken", "Blaziken",
        "Mudkip", "Marshtomp", "Swampert", "Poochyena", "Mightyena", "Zigzagoon",
        "Linoone", "Wurmple", "Silcoon", "Beautifly", "Cascoon", "Dustox",
        "Lotad", "Lombre", "Ludicolo", "Seedot", "Nuzleaf", "Shiftry",
        "Taillow", "Swellow", "Wingull", "Pelipper", "Ralts", "Kirlia",
        "Gardevoir", "Surskit", "Masquerain", "Shroomish", "Breloom", "Slakoth",
        "Vigoroth", "Slaking", "Nincada", "Ninjask", "Shedinja", "Whismur",
        "Loudred", "Exploud", "Makuhita", "Hariyama", "Azurill", "Nosepass",
        "Skitty", "Delcatty", "Sableye", "Mawile", "Aron", "Lairon", "Aggron",
        "Meditite", "Medicham", "Electrike", "Manectric", "Plusle", "Minun",
        "Volbeat", "Illumise", "Roselia", "Gulpin", "Swalot", "Carvanha",
        "Sharpedo", "Wailmer", "Wailord", "Numel", "Camerupt", "Torkoal",
        "Spoink", "Grumpig", "Spinda", "Trapinch", "Vibrava", "Flygon",
        "Cacnea", "Cacturne", "Swablu", "Altaria", "Zangoose", "Seviper",
        "Lunatone", "Solrock", "Barboach", "Whiscash", "Corphish", "Crawdaunt",
        "Baltoy", "Claydol", "Lileep", "Cradily", "Anorith", "Armaldo",
        "Feebas", "Milotic", "Castform", "Kecleon", "Shuppet", "Banette",
        "Duskull", "Dusclops", "Tropius", "Chimecho", "Absol", "Wynaut",
        "Snorunt", "Glalie", "Spheal", "Sealeo", "Walrein", "Clamperl",
        "Huntail", "Gorebyss", "Relicanth", "Luvdisc", "Bagon", "Shelgon",
        "Salamence", "Beldum", "Metang", "Metagross", "Regirock", "Regice",
        "Registeel", "Latias", "Latios", "Kyogre", "Groudon", "Rayquaza",
        "Jirachi", "Deoxys",
    ]

    public static let gen4Names: [String] = [
        "Turtwig", "Grotle", "Torterra", "Chimchar", "Monferno", "Infernape",
        "Piplup", "Prinplup", "Empoleon", "Starly", "Staravia", "Staraptor",
        "Bidoof", "Bibarel", "Kricketot", "Kricketune", "Shinx", "Luxio",
        "Luxray", "Budew", "Roserade", "Cranidos", "Rampardos", "Shieldon",
        "Bastiodon", "Burmy", "Wormadam", "Mothim", "Combee", "Vespiquen",
        "Pachirisu", "Buizel", "Floatzel", "Cherubi", "Cherrim", "Shellos",
        "Gastrodon", "Ambipom", "Drifloon", "Drifblim", "Buneary", "Lopunny",
        "Mismagius", "Honchkrow", "Glameow", "Purugly", "Chingling", "Stunky",
        "Skuntank", "Bronzor", "Bronzong", "Bonsly", "Mime Jr.", "Happiny",
        "Chatot", "Spiritomb", "Gible", "Gabite", "Garchomp", "Munchlax",
        "Riolu", "Lucario", "Hippopotas", "Hippowdon", "Skorupi", "Drapion",
        "Croagunk", "Toxicroak", "Carnivine", "Finneon", "Lumineon", "Mantyke",
        "Snover", "Abomasnow", "Weavile", "Magnezone", "Lickilicky", "Rhyperior",
        "Tangrowth", "Electivire", "Magmortar", "Togekiss", "Yanmega", "Leafeon",
        "Glaceon", "Gliscor", "Mamoswine", "Porygon-Z", "Gallade", "Probopass",
        "Dusknoir", "Froslass", "Rotom", "Uxie", "Mesprit", "Azelf",
        "Dialga", "Palkia", "Heatran", "Regigigas", "Giratina", "Cresselia",
        "Phione", "Manaphy", "Darkrai", "Shaymin", "Arceus",
    ]

    public static let names = Gen1Pokedex.names + gen2Names + gen3Names + gen4Names

    /// Display name for a national-dex number, or nil if out of range.
    public static func name(for dex: Int) -> String? {
        guard dexRange.contains(dex) else { return nil }
        return names[dex - 1]
    }

    /// Species summary for a national-dex number, or nil when unsupported.
    public static func description(for dex: Int) -> String? {
        if let description = Gen1Pokedex.description(for: dex) { return description }
        if let description = Gen2Pokedex.description(for: dex) { return description }
        if let description = Gen3Pokedex.description(for: dex) { return description }
        return Gen4Pokedex.description(for: dex)
    }
}

public enum Gen4Pokedex {
    public static let dexRange = 387...493
    public static var count: Int { names.count }
    public static let names = PokemonPokedex.gen4Names
    public static let descriptions = names.map {
        "\($0) is a Pokémon originally discovered in the Sinnoh region."
    }

    public static func name(for dex: Int) -> String? {
        guard dexRange.contains(dex) else { return nil }
        return names[dex - dexRange.lowerBound]
    }

    public static func description(for dex: Int) -> String? {
        guard dexRange.contains(dex) else { return nil }
        return descriptions[dex - dexRange.lowerBound]
    }
}

public enum Gen3Pokedex {
    public static let dexRange = 252...386
    public static var count: Int { names.count }
    public static let names = PokemonPokedex.gen3Names
    public static let descriptions = names.map {
        "\($0) is a Pokémon originally discovered in the Hoenn region."
    }

    public static func name(for dex: Int) -> String? {
        guard dexRange.contains(dex) else { return nil }
        return names[dex - dexRange.lowerBound]
    }

    public static func description(for dex: Int) -> String? {
        guard dexRange.contains(dex) else { return nil }
        return descriptions[dex - dexRange.lowerBound]
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
