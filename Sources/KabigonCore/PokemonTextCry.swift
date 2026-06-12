import Foundation

/// Short, speech-bubble-friendly vocalizations derived from each species name.
public enum PokemonTextCry {
    public static func lines(for dex: Int) -> [String] {
        guard let name = PokemonPokedex.name(for: dex) else { return [] }
        switch dex {
        case 25: return ["Pika-pika!", "Pikachu!"]
        case 39: return ["Jigglypuff~", "Jiggly!"]
        case 52: return ["Meowth, that's right!", "Meowth!"]
        case 54: return ["Psy? Psyduck!", "Psy-yai-yai!"]
        case 122: return ["Mime-mime!", "Mr. Mime!"]
        case 129: return ["Karp! Karp!", "Magikarp!"]
        case 133: return ["Vee-vee!", "Eevee!"]
        case 143: return ["Snor... lax!", "Snorlax!"]
        case 175: return ["Toge-toge-prii!", "Togepi!"]
        case 202: return ["Wob-buffet!", "Wobbuffet!"]
        case 387: return ["Turt-turtwig!", "Turtwig!"]
        case 390: return ["Chim-char!", "Chimchar!"]
        case 393: return ["Pip-piplup!", "Piplup!"]
        default:
            let voice = vocalStem(name)
            return ["\(voice)!", "\(voice)-\(voice)!"]
        }
    }

    private static func vocalStem(_ name: String) -> String {
        let cleaned = name.split(whereSeparator: { !$0.isLetter }).first.map(String.init) ?? name
        guard cleaned.count > 5 else { return cleaned }
        let end = cleaned.index(cleaned.startIndex, offsetBy: min(4, cleaned.count))
        return String(cleaned[..<end])
    }
}
