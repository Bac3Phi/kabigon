import AppKit
import KabigonCore

/// Downloads a single species' PMD assets from PMDCollab's SpriteCollab at
/// runtime and writes them into the on-disk cache in the same layout the bundled
/// assets use. This lets a freshly encountered Pokémon become playable without
/// shipping every supported sprite set inside the app.
enum PMDAssetDownloader {
    private static let raw = "https://raw.githubusercontent.com/PMDCollab/SpriteCollab/master"
    private static let wantedAnims = [
        "Idle", "Walk", "Sleep", "Hurt", "Eat", "Pose", "Charge", "Nod", "Hop",
        "Attack", "Shoot", "Shake", "Swing", "Double", "Rotate", "EventSleep", "Wake",
        "Tumble", "Pain", "Float", "DeepBreath", "Sit", "LookUp", "Sink", "Trip",
        "Laying", "LeapForth", "Head", "Cringe", "LostBalance", "TumbleBack",
        "Faint", "HitGround", "Pull",
    ]
    private static let wantedEmotions = [
        "Normal", "Happy", "Sad", "Angry", "Worried", "Determined",
        "Joyous", "Inspired", "Surprised", "Crying", "Pain", "Dizzy",
    ]

    /// Root of the runtime asset cache in Application Support.
    static var cacheRoot: URL {
        URL(fileURLWithPath: KabigonPaths.baseDir).appendingPathComponent("pmd-cache")
    }

    static func cacheDir(dex: Int) -> URL {
        cacheRoot.appendingPathComponent(String(format: "%04d", dex))
    }

    /// True once a usable `meta.json` exists on disk for this species.
    static func isCached(dex: Int) -> Bool {
        let meta = cacheDir(dex: dex).appendingPathComponent("meta.json")
        return FileManager.default.fileExists(atPath: meta.path) && hasModernMeta(meta)
    }

    /// Fetches, slices, and writes a species. Returns true on success. Safe to
    /// call off the main actor: it only touches the network and file system.
    static func download(dex: Int, force: Bool = false) async -> Bool {
        if isCached(dex: dex), !force { return true }
        let slug = String(format: "%04d", dex)
        let dir = cacheDir(dex: dex)
        let animDir = dir.appendingPathComponent("anim")
        let portraitDir = dir.appendingPathComponent("portrait")
        let fm = FileManager.default
        if force {
            try? fm.removeItem(at: dir)
        }
        try? fm.createDirectory(at: animDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: portraitDir, withIntermediateDirectories: true)

        guard let xml = await fetch("sprite/\(slug)/AnimData.xml"),
              let specs = parseAnimData(xml), !specs.isEmpty else { return false }

        var animMeta: [String: Any] = [:]
        for anim in wantedAnims {
            guard let spec = specs[anim],
                  let sheetData = await fetch("sprite/\(slug)/\(anim)-Anim.png"),
                  let sheet = cgImage(sheetData) else { continue }
            let count = spec.durations.isEmpty ? (sheet.width / max(spec.fw, 1)) : spec.durations.count
            let variants = animationRows(sheet, fw: spec.fw, fh: spec.fh, count: count)
            guard let firstVariant = variants.first, !firstVariant.isEmpty else { continue }
            let clipDir = animDir.appendingPathComponent(anim)
            try? fm.removeItem(at: clipDir)
            try? fm.createDirectory(at: clipDir, withIntermediateDirectories: true)
            for (variantIndex, frames) in variants.enumerated() {
                let variantDir = clipDir.appendingPathComponent("\(variantIndex)")
                try? fm.createDirectory(at: variantDir, withIntermediateDirectories: true)
                for (i, frame) in frames.enumerated() {
                    savePNG(frame, to: variantDir.appendingPathComponent("\(i).png"))
                }
            }
            let durs = spec.durations.isEmpty
                ? Array(repeating: 4, count: firstVariant.count)
                : Array(spec.durations.prefix(firstVariant.count))
            animMeta[anim] = [
                "frameCount": firstVariant.count,
                "variantCount": variants.count,
                "durations": durs,
            ]
        }
        guard !animMeta.isEmpty else { return false }

        var emotions: [String] = []
        for emotion in wantedEmotions {
            guard let data = await fetch("portrait/\(slug)/\(emotion).png"),
                  let cg = cgImage(data) else { continue }
            savePNG(cg, to: portraitDir.appendingPathComponent("\(emotion).png"))
            emotions.append(emotion)
        }

        let meta: [String: Any] = ["dex": dex, "anims": animMeta, "portraits": emotions]
        guard let metaData = try? JSONSerialization.data(
            withJSONObject: meta, options: [.sortedKeys]) else { return false }
        try? metaData.write(to: dir.appendingPathComponent("meta.json"))
        return true
    }

    // MARK: Helpers

    private static func fetch(_ path: String) async -> Data? {
        guard let url = URL(string: "\(raw)/\(path)") else { return nil }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse).map({ $0.statusCode == 200 }) ?? true
        else { return nil }
        return data
    }

    private static func cgImage(_ data: Data) -> CGImage? {
        NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    private static func savePNG(_ cg: CGImage, to url: URL) {
        let rep = NSBitmapImageRep(cgImage: cg)
        rep.size = NSSize(width: cg.width, height: cg.height)
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: url)
        }
    }

    private static func hasModernMeta(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let anims = json["anims"] as? [String: Any] else { return false }
        return anims.values.contains { anim in
            (anim as? [String: Any])?["variantCount"] != nil
        }
    }

    private struct AnimSpec { let fw: Int; let fh: Int; let durations: [Int] }

    private static func parseAnimData(_ data: Data) -> [String: AnimSpec]? {
        guard let doc = try? XMLDocument(data: data) else { return nil }
        var out: [String: AnimSpec] = [:]
        let nodes = (try? doc.nodes(forXPath: "//Anim")) ?? []
        for node in nodes {
            guard let el = node as? XMLElement else { continue }
            func child(_ n: String) -> String? { el.elements(forName: n).first?.stringValue }
            guard let name = child("Name"),
                  let fw = child("FrameWidth").flatMap({ Int($0) }),
                  let fh = child("FrameHeight").flatMap({ Int($0) }) else { continue }
            let durs = el.elements(forName: "Durations").first?
                .elements(forName: "Duration").compactMap { Int($0.stringValue ?? "") } ?? []
            out[name] = AnimSpec(fw: fw, fh: fh, durations: durs)
        }
        return out
    }

    private static func animationRows(_ sheet: CGImage, fw: Int, fh: Int, count: Int) -> [[CGImage]] {
        guard fw > 0, fh > 0 else { return [] }
        let cols = sheet.width / fw
        let rows = max(sheet.height / fh, 1)
        let n = min(max(count, 1), cols)
        var variants: [[CGImage]] = []
        for row in 0..<rows {
            var frames: [CGImage] = []
            for c in 0..<n {
                let rect = CGRect(x: c * fw, y: row * fh, width: fw, height: fh)
                if let cropped = sheet.cropping(to: rect) { frames.append(cropped) }
            }
            if !frames.isEmpty {
                variants.append(frames)
            }
        }
        return variants
    }
}
