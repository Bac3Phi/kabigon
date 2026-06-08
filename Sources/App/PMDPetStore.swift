import AppKit
import KabigonCore

/// One animation clip: its frames and per-frame PMD durations (frame units).
struct PMDAnim {
    let frames: [NSImage]
    let durations: [Int]
}

/// A fully loaded species: its animation clips and emotion portraits, sliced
/// from the bundled SpriteCollab assets.
struct PMDLoadedSpecies {
    let dex: Int
    let anims: [String: PMDAnim]
    let portraits: [String: NSImage]

    /// Canonical body height (the idle frame), used to scale every clip to a
    /// stable on-screen size.
    var referenceHeight: CGFloat {
        anims["Idle"]?.frames.first?.size.height ?? 40
    }

    func anim(_ name: String) -> PMDAnim? { anims[name] }
    func portrait(_ name: String) -> NSImage? { portraits[name] }
}

/// Loads and caches the bundled PMD species assets from `Resources/pmd/`.
@MainActor
final class PMDPetStore: ObservableObject {
    static let shared = PMDPetStore()

    @Published private(set) var cache: [Int: PMDLoadedSpecies] = [:]
    @Published private(set) var loading: Set<Int> = []
    @Published private(set) var failed: Set<Int> = []

    private struct AnimMeta: Decodable { let frameCount: Int; let durations: [Int] }
    private struct SpeciesMeta: Decodable {
        let dex: Int
        let anims: [String: AnimMeta]
        let portraits: [String]
    }

    /// Cache lookup only — safe to call from a view body (no mutation).
    func loaded(dex: Int) -> PMDLoadedSpecies? { cache[dex] }

    /// Loads a species into the cache from disk if its assets are present (does
    /// not hit the network — use `ensureLoaded` for that).
    func preload(_ dex: Int) {
        guard cache[dex] == nil, let species = load(dex: dex) else { return }
        cache[dex] = species
    }

    /// Whether a species' assets exist on disk (bundled or already downloaded).
    func isAvailable(dex: Int) -> Bool {
        cache[dex] != nil || metaDir(dex: dex) != nil
    }

    func isLoading(dex: Int) -> Bool { loading.contains(dex) }
    func didFail(dex: Int) -> Bool { failed.contains(dex) }

    /// Loads a species, downloading its assets first if they are not on disk.
    /// Use this for freshly encountered Pokémon outside the bundled set.
    func ensureLoaded(dex: Int, forceDownload: Bool = false) async {
        if cache[dex] != nil { return }
        if !forceDownload {
            preload(dex)
            if cache[dex] != nil {
                failed.remove(dex)
                return
            }
        }
        guard !loading.contains(dex) else { return }
        loading.insert(dex)
        defer { loading.remove(dex) }

        let ok = await PMDAssetDownloader.download(dex: dex, force: forceDownload)
        guard ok, let species = load(dex: dex) else {
            failed.insert(dex)
            return
        }
        cache[dex] = species
        failed.remove(dex)
    }

    func retry(dex: Int) {
        cache[dex] = nil
        failed.remove(dex)
        Task { await ensureLoaded(dex: dex, forceDownload: true) }
    }

    private var bundleRootURL: URL? {
        let appResource = Bundle.main.resourceURL?.appendingPathComponent("pmd")
        if let appResource, FileManager.default.fileExists(atPath: appResource.path) {
            return appResource
        }
        return Bundle.module.url(forResource: "pmd", withExtension: nil)
    }

    /// The directory holding a species' `meta.json`, preferring the downloaded
    /// cache over the bundled assets, or nil if neither exists.
    private func metaDir(dex: Int) -> URL? {
        let fm = FileManager.default
        let cacheDir = PMDAssetDownloader.cacheDir(dex: dex)
        if fm.fileExists(atPath: cacheDir.appendingPathComponent("meta.json").path) {
            return cacheDir
        }
        if let bundle = bundleRootURL {
            let bundleDir = bundle.appendingPathComponent(String(format: "%04d", dex))
            if fm.fileExists(atPath: bundleDir.appendingPathComponent("meta.json").path) {
                return bundleDir
            }
        }
        return nil
    }

    private func load(dex: Int) -> PMDLoadedSpecies? {
        guard let dir = metaDir(dex: dex) else { return nil }
        guard let metaData = try? Data(contentsOf: dir.appendingPathComponent("meta.json")),
              let meta = try? JSONDecoder().decode(SpeciesMeta.self, from: metaData) else { return nil }

        var anims: [String: PMDAnim] = [:]
        for (name, animMeta) in meta.anims {
            let clipDir = dir.appendingPathComponent("anim").appendingPathComponent(name)
            var frames: [NSImage] = []
            for i in 0..<animMeta.frameCount {
                let url = clipDir.appendingPathComponent("\(i).png")
                if let img = NSImage(contentsOf: url) { frames.append(img) }
            }
            guard !frames.isEmpty else { continue }
            anims[name] = PMDAnim(frames: frames, durations: animMeta.durations)
        }

        var portraits: [String: NSImage] = [:]
        for emotion in meta.portraits {
            let url = dir.appendingPathComponent("portrait").appendingPathComponent("\(emotion).png")
            if let img = NSImage(contentsOf: url) { portraits[emotion] = img }
        }

        guard !anims.isEmpty else { return nil }
        return PMDLoadedSpecies(dex: meta.dex, anims: anims, portraits: portraits)
    }
}

/// Maps the aggregate pet mood to a PMD animation clip and emotion portrait.
enum PMDMoodMap {
    /// Preferred clip names by mood, in fallback order (Idle is the safety net).
    static func animNames(for mood: PetMood) -> [String] {
        switch mood {
        case .idle: return ["Idle"]
        case .working: return ["Charge", "Walk", "Idle"]
        case .waiting: return ["Pose", "Idle"]
        case .done: return ["Nod", "Pose", "Idle"]
        case .celebrate: return ["Hop", "Pose", "Idle"]
        }
    }

    /// Resolves the first available clip for a mood from a loaded species.
    static func anim(for mood: PetMood, in species: PMDLoadedSpecies) -> PMDAnim? {
        for name in animNames(for: mood) {
            if let clip = species.anim(name) { return clip }
        }
        return species.anims.values.first
    }

    /// Emotion portrait name for a mood, in fallback order (Normal is the net).
    static func emotionNames(for mood: PetMood) -> [String] {
        switch mood {
        case .idle: return ["Normal"]
        case .working: return ["Determined", "Normal"]
        case .waiting: return ["Worried", "Sad", "Normal"]
        case .done: return ["Happy", "Joyous", "Normal"]
        case .celebrate: return ["Joyous", "Happy", "Normal"]
        }
    }

    static func portrait(for mood: PetMood, in species: PMDLoadedSpecies) -> NSImage? {
        for name in emotionNames(for: mood) {
            if let img = species.portrait(name) { return img }
        }
        return species.portraits["Normal"] ?? species.portraits.values.first
    }
}
