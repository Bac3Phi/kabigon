import Foundation

/// One of the SpriteCollab portrait emotions bundled with each species. The raw
/// value matches the portrait file name (e.g. `.happy` → `portrait/Happy.png`),
/// so a resolved emotion maps directly onto an on-disk asset.
public enum PetEmotion: String, Sendable, CaseIterable {
    case normal = "Normal"
    case happy = "Happy"
    case sad = "Sad"
    case angry = "Angry"
    case worried = "Worried"
    case determined = "Determined"
    case joyous = "Joyous"
    case inspired = "Inspired"
    case surprised = "Surprised"
    case crying = "Crying"
    case pain = "Pain"
    case dizzy = "Dizzy"

    public var portraitName: String { rawValue }
}

/// Picks the facial expression that best fits what the agent is currently doing.
/// It starts from the coarse mood, then refines using keywords in the agent's
/// status message (the running tool, or the reason it is waiting) so the pet's
/// face reacts to context rather than just the five high-level states.
public enum EmotionResolver {
    public static func resolve(mood: PetMood, message: String?) -> PetEmotion {
        let text = (message ?? "").lowercased()

        // A failure shows on the face no matter the surrounding state.
        if matches(text, errorKeywords) {
            return mood == .waiting ? .crying : .pain
        }

        switch mood {
        case .idle:
            return .normal
        case .working:
            if matches(text, searchKeywords) { return .inspired }
            if matches(text, testKeywords) { return .surprised }
            return .determined
        case .waiting:
            if matches(text, questionKeywords) { return .surprised }
            return .worried
        case .done:
            return .happy
        case .celebrate:
            return .joyous
        }
    }

    private static func matches(_ text: String, _ keys: [String]) -> Bool {
        guard !text.isEmpty else { return false }
        return keys.contains { text.contains($0) }
    }

    private static let errorKeywords = [
        "error", "fail", "exception", "denied", "crash", "cannot",
        "can't", "not found", "invalid", "❌",
    ]
    private static let searchKeywords = [
        "search", "read", "look", "find", "grep", "explore", "scan", "fetch", "browse",
    ]
    private static let testKeywords = ["test", "verify", "check", "lint", "run"]
    private static let questionKeywords = [
        "?", "approve", "permission", "confirm", "allow", "choose", "input", "review",
    ]
}
