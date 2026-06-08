import Foundation
import KabigonCore

struct PetReactionEvent: Equatable {
    let id = UUID()
    let symbol: String
    let animationNames: [String]
}

/// Resolves the aggregate session mood, plays a short `celebrate` burst when
/// work finishes, owns the selected (imported) pet, and drives the chat bubble.
@MainActor
final class PetController: ObservableObject {
    static let shared = PetController()

    @Published private(set) var mood: PetMood = .idle
    @Published private(set) var chatLine: String = ""
    /// The facial expression to show, refined from the active agent's context.
    @Published private(set) var emotion: PetEmotion = .normal
    @Published private(set) var petReaction: PetReactionEvent?
    @Published private(set) var workingVisualStyle: WorkingVisualStyle = .thinking

    @Published var selectedPetID: String? {
        didSet { UserDefaults.standard.set(selectedPetID, forKey: Self.petKey) }
    }
    @Published var showChat: Bool {
        didSet {
            UserDefaults.standard.set(showChat, forKey: Self.chatKey)
            refreshChat()
        }
    }
    /// Sprite point size, freely adjustable via a slider.
    @Published var petPoint: Double {
        didSet { UserDefaults.standard.set(petPoint, forKey: Self.sizeKey) }
    }

    static let minPoint: Double = 60
    static let maxPoint: Double = 240
    static let presets: [(String, Double)] = [("S", 84), ("M", 120), ("L", 168)]

    /// Floating window size for a sprite point size (room for the bubble above).
    static func windowSize(forPoint point: Double) -> CGSize {
        CGSize(width: max(point + 160, 300), height: point + 112)
    }
    var windowSize: CGSize { Self.windowSize(forPoint: petPoint) }

    private var lastResolved: PetMood = .idle
    private var latestSessions: [AgentSession] = []
    private var celebrateTimer: Timer?
    private var chatTimer: Timer?
    private var chatHideTimer: Timer?
    private var petReactionTimer: Timer?

    private static let petKey = "agentpet.selectedPetID"
    private static let chatKey = "agentpet.showChat"
    private static let sizeKey = "agentpet.petSize"
    private static let celebrateDuration: TimeInterval = 3
    private static let chatDisplayDuration: TimeInterval = 4

    init() {
        selectedPetID = UserDefaults.standard.string(forKey: Self.petKey)
        showChat = (UserDefaults.standard.object(forKey: Self.chatKey) as? Bool) ?? true
        let saved = UserDefaults.standard.object(forKey: Self.sizeKey) as? Double ?? 120
        petPoint = min(max(saved, Self.minPoint), Self.maxPoint)
    }

    func start() {
        scheduleNextChat()
    }

    private var sizeAnimTimer: Timer?
    private var sizeAnimStep = 0
    private var sizeAnimStart = 0.0
    private var sizeAnimTarget = 0.0
    private static let sizeAnimSteps = 14

    /// Eases `petPoint` to a target so a preset tap resizes as smoothly as a
    /// slider drag (each step drives the same smooth window resize).
    func animateSize(to target: Double) {
        sizeAnimTimer?.invalidate()
        sizeAnimTarget = min(max(target, Self.minPoint), Self.maxPoint)
        sizeAnimStart = petPoint
        sizeAnimStep = 0
        sizeAnimTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor [weak self] in self?.tickSize() }
        }
    }

    private func tickSize() {
        sizeAnimStep += 1
        let t = min(Double(sizeAnimStep) / Double(Self.sizeAnimSteps), 1)
        let eased = t * t * (3 - 2 * t)   // smoothstep
        petPoint = sizeAnimStart + (sizeAnimTarget - sizeAnimStart) * eased
        if sizeAnimStep >= Self.sizeAnimSteps {
            petPoint = sizeAnimTarget
            sizeAnimTimer?.invalidate()
        }
    }

    /// Called by the daemon whenever the session list changes.
    func update(sessions: [AgentSession]) {
        latestSessions = sessions
        let resolved = MoodResolver.aggregate(sessions)
        defer { lastResolved = resolved }

        if resolved == .done && lastResolved != .done {
            setMood(.celebrate)
            celebrateTimer?.invalidate()
            celebrateTimer = Timer.scheduledTimer(withTimeInterval: Self.celebrateDuration, repeats: false) { _ in
                Task { @MainActor [weak self] in self?.settleAfterCelebrate() }
            }
            return
        }
        if mood == .celebrate && resolved == .done {
            return  // let the celebration finish
        }
        celebrateTimer?.invalidate()
        setMood(resolved)
    }

    private func settleAfterCelebrate() {
        setMood(MoodResolver.aggregate(latestSessions), announce: false)
    }

    private func setMood(_ newMood: PetMood, announce: Bool = true) {
        let changed = mood != newMood
        mood = newMood
        if newMood == .working {
            workingVisualStyle = resolveWorkingVisualStyle(message: representativeMessage(for: newMood))
        }
        if petReactionTimer == nil {
            emotion = EmotionResolver.resolve(mood: newMood, message: representativeMessage(for: newMood))
        }
        if changed {
            if announce {
                refreshChat()
            } else {
                dismissChat()
            }
            scheduleNextChat()
        }
    }

    private func resolveWorkingVisualStyle(message: String?) -> WorkingVisualStyle {
        let text = (message ?? "").lowercased()
        if ["search", "find", "read", "browse", "scan", "inspect", "explore"].contains(where: text.contains) {
            return .searching
        }
        if ["test", "verify", "check", "lint", "build"].contains(where: text.contains) {
            return .testing
        }
        if ["using", "run", "write", "edit", "patch", "command", "tool"].contains(where: text.contains) {
            return .executing
        }
        return .thinking
    }

    /// Gives petting varied personality: a temporary portrait emotion, visual
    /// reaction symbol, sprite animation, and spoken response before returning
    /// to agent context.
    func reactToPet() {
        let reactions: [(PetEmotion, String, String, [String])] = [
            (.happy, "heart.fill", "That feels nice!", ["Nod", "Pose", "Idle"]),
            (.joyous, "sparkles", "More cuddles!", ["Hop", "Pose", "Idle"]),
            (.surprised, "exclamationmark.bubble.fill", "Oh! You surprised me!", ["Hurt", "Pose", "Idle"]),
            (.inspired, "lightbulb.fill", "I feel energized!", ["Charge", "Pose", "Idle"]),
            (.dizzy, "tornado", "Hehe, easy there!", ["Spin", "Hurt", "Idle"]),
            (.determined, "bolt.heart.fill", "We're a great team!", ["Attack", "Charge", "Idle"]),
        ]
        guard let reaction = reactions.randomElement() else { return }
        presentReaction(
            emotion: reaction.0, symbol: reaction.1, message: reaction.2,
            animationNames: reaction.3, duration: 2.2
        )
    }

    /// Announces a newly caught Pokémon through the currently active pet.
    func reactToEncounter(name: String, level: Int) {
        presentReaction(
            emotion: .surprised,
            symbol: "sparkles",
            message: "Look! A wild \(name) appeared at Lv \(level)!",
            animationNames: ["Hop", "Pose", "Nod", "Idle"],
            duration: 3.2
        )
    }

    private func presentReaction(
        emotion: PetEmotion,
        symbol: String,
        message: String,
        animationNames: [String],
        duration: TimeInterval
    ) {
        petReactionTimer?.invalidate()
        chatHideTimer?.invalidate()
        self.emotion = emotion
        petReaction = PetReactionEvent(symbol: symbol, animationNames: animationNames)
        if showChat { chatLine = message }
        StatusBarController.shared.refreshTitle()
        petReactionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.petReactionTimer = nil
                self.petReaction = nil
                self.dismissChat()
                self.setMood(self.mood, announce: false)
            }
        }
    }

    /// The status message of the session that best represents the current mood,
    /// so the pet's expression reflects what that agent is actually doing.
    private func representativeMessage(for mood: PetMood) -> String? {
        let target: AgentState?
        switch mood {
        case .working: target = .working
        case .waiting: target = .waiting
        case .done, .celebrate: target = .done
        case .idle: target = nil
        }
        guard let target else { return nil }
        return latestSessions.first { $0.state == target }?.message
    }

    private func refreshChat() {
        guard petReactionTimer == nil else { return }
        var pool = ChatSettings.shared.lines(for: mood)
        if ChatSettings.shared.source == .system {
            pool += PokemonDialogue.lines(for: ProgressStore.shared.displayDex, mood: mood)
        }
        guard showChat, !pool.isEmpty else {
            chatLine = ""
            StatusBarController.shared.refreshTitle()
            return
        }
        chatLine = pool.randomElement() ?? ""
        StatusBarController.shared.refreshTitle()
        chatHideTimer?.invalidate()
        chatHideTimer = Timer.scheduledTimer(
            withTimeInterval: Self.chatDisplayDuration,
            repeats: false
        ) { _ in
            Task { @MainActor [weak self] in self?.dismissChat() }
        }
    }

    private func dismissChat() {
        chatHideTimer?.invalidate()
        chatLine = ""
        StatusBarController.shared.refreshTitle()
    }

    private func scheduleNextChat() {
        chatTimer?.invalidate()
        let delay: TimeInterval
        switch mood {
        case .working:
            delay = .random(in: 25...40)
        case .waiting:
            delay = .random(in: 45...70)
        case .idle, .done:
            delay = .random(in: 60...90)
        case .celebrate:
            return
        }
        chatTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.refreshChat()
                self.scheduleNextChat()
            }
        }
    }
}

/// Built-in (system) chat lines per mood.
enum PetChat {
    static let lines: [PetMood: [String]] = [
        .idle: [
            "I'm right here.", "Keeping watch.", "Ready when you are.",
            "Let's pick a task.", "I'll stay close.",
        ],
        .working: [
            "Thinking…", "Working on it…", "On it!", "Crunching code…",
            "Hmm, let me see…", "Cooking something up…", "Deep in thought…",
            "Brain go brrr…", "Almost there…", "Wiring it up…",
        ],
        .waiting: [
            "I need you!", "Your turn 👀", "Waiting on you…", "Can you check this?",
            "Psst, need input!", "Awaiting orders…", "Help me out?", "Stuck, need you!",
        ],
        .done: [
            "All done! ✅", "Finished!", "Ta-da!", "Done and dusted!",
            "Nailed it!", "That's a wrap!", "Mission complete!",
        ],
        .celebrate: [
            "🎉 Woohoo!", "We did it!", "Victory!", "Yesss!", "High five! 🙌", "Champion!",
        ],
    ]
}

enum PokemonDialogue {
    static func lines(for dex: Int, mood: PetMood) -> [String] {
        let name = Gen1Pokedex.name(for: dex) ?? "buddy"
        let species = speciesLines(for: dex)
        switch mood {
        case .idle:
            return species.idle + [
                "\(name) is watching your workspace.",
                "\(name) looks ready to help.",
            ]
        case .working:
            return species.working + [
                "\(name) is focusing with you.",
                "\(name) is following the thread.",
            ]
        case .waiting:
            return [
                "\(name) is waiting for your call.",
                "\(name) tilts its head.",
            ]
        case .done:
            return species.done + [
                "\(name) looks proud.",
                "\(name) gives a satisfied nod.",
            ]
        case .celebrate:
            return species.celebrate + [
                "\(name) is celebrating!",
                "\(name) bounces happily.",
            ]
        }
    }

    private static func speciesLines(for dex: Int) -> (
        idle: [String],
        working: [String],
        done: [String],
        celebrate: [String]
    ) {
        switch dex {
        case 1:
            return (
                ["Bulbasaur soaks up a little sunlight.", "Bulbasaur gives a calm nod."],
                ["Bulbasaur steadies the plan.", "Bulbasaur keeps the seed of an idea safe."],
                ["Bulbasaur relaxes its vines.", "Bulbasaur looks pleased with the result."],
                ["Bulbasaur's bulb wiggles happily.", "Bulbasaur hops in a tiny circle."]
            )
        case 2:
            return (
                ["Ivysaur's bud gives off a faint sweet scent.", "Ivysaur watches patiently."],
                ["Ivysaur digs in and focuses.", "Ivysaur braces for the next step."],
                ["Ivysaur gives a confident huff.", "Ivysaur lowers its guard."],
                ["Ivysaur's bud sways with excitement.", "Ivysaur celebrates with a proud stomp."]
            )
        case 3:
            return (
                ["Venusaur rests under its broad flower.", "Venusaur breathes slowly."],
                ["Venusaur anchors the team.", "Venusaur studies the problem carefully."],
                ["Venusaur lets out a deep, happy rumble.", "Venusaur looks satisfied."],
                ["Venusaur's flower shakes with joy.", "Venusaur celebrates with a gentle roar."]
            )
        case 4:
            return (
                ["Charmander's tail flame flickers warmly.", "Charmander looks eager."],
                ["Charmander fires up for the task.", "Charmander scratches out a plan."],
                ["Charmander beams at the finished work.", "Charmander's flame burns bright."],
                ["Charmander cheers with a bright flame.", "Charmander does a small victory hop."]
            )
        case 5:
            return (
                ["Charmeleon taps one claw impatiently.", "Charmeleon keeps its flame steady."],
                ["Charmeleon charges straight at the problem.", "Charmeleon narrows its eyes and focuses."],
                ["Charmeleon flashes a sharp grin.", "Charmeleon looks fired up by the result."],
                ["Charmeleon celebrates with a quick flourish.", "Charmeleon's tail flares proudly."]
            )
        case 6:
            return (
                ["Charizard folds its wings and watches.", "Charizard's tail burns steadily."],
                ["Charizard scans the path ahead.", "Charizard pushes through the hard part."],
                ["Charizard gives a proud nod.", "Charizard looks ready for the next challenge."],
                ["Charizard lifts its wings in triumph.", "Charizard lets out a victorious roar."]
            )
        case 7:
            return (
                ["Squirtle peeks out from its shell.", "Squirtle gives a tiny wave."],
                ["Squirtle keeps things flowing.", "Squirtle studies the next move."],
                ["Squirtle smiles at the clean finish.", "Squirtle looks pleased."],
                ["Squirtle spins happily.", "Squirtle celebrates with a little splash."]
            )
        case 8:
            return (
                ["Wartortle's ears twitch.", "Wartortle keeps a careful watch."],
                ["Wartortle balances the details.", "Wartortle stays steady under pressure."],
                ["Wartortle gives a practiced nod.", "Wartortle looks quietly proud."],
                ["Wartortle's tail swishes happily.", "Wartortle celebrates with a neat spin."]
            )
        case 9:
            return (
                ["Blastoise stands guard.", "Blastoise rests with calm confidence."],
                ["Blastoise lines up the next shot.", "Blastoise powers through the task."],
                ["Blastoise lowers its cannons with a smile.", "Blastoise looks satisfied."],
                ["Blastoise celebrates with a heavy stomp.", "Blastoise gives a triumphant grin."]
            )
        default:
            return (
                ["\(Gen1Pokedex.name(for: dex) ?? "This Pokémon") stays close.", "\(Gen1Pokedex.name(for: dex) ?? "This Pokémon") watches your work."],
                ["\(Gen1Pokedex.name(for: dex) ?? "This Pokémon") focuses with you.", "\(Gen1Pokedex.name(for: dex) ?? "This Pokémon") keeps pace."],
                ["\(Gen1Pokedex.name(for: dex) ?? "This Pokémon") looks pleased.", "\(Gen1Pokedex.name(for: dex) ?? "This Pokémon") relaxes."],
                ["\(Gen1Pokedex.name(for: dex) ?? "This Pokémon") celebrates with you.", "\(Gen1Pokedex.name(for: dex) ?? "This Pokémon") looks thrilled."]
            )
        }
    }
}
