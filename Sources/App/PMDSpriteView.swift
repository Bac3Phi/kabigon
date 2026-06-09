import SwiftUI
import KabigonCore

/// Renders a loaded PMD species: plays the mood's animation clip honouring its
/// per-frame durations, scaled to a stable on-screen size and bottom-anchored so
/// the feet stay planted, with the shared mood motion and overlays on top.
struct PMDSpriteView: View {
    let species: PMDLoadedSpecies
    let mood: PetMood
    var size: CGFloat = 120
    var preferredAnimNames: [String]? = nil
    var workingStyle: WorkingVisualStyle? = nil

    /// PMD durations are in ~30fps frame units.
    private static let unit: Double = 1.0 / 30.0

    var body: some View {
        TimelineView(.animation(minimumInterval: Self.unit)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let motion = PetMotion.resolve(mood, t, workingStyle: workingStyle)
            ZStack(alignment: .bottom) {
                MoodAccessories(mood: mood, t: t, size: size, workingStyle: workingStyle)
                sprite(at: t, motion: motion)
            }
            .frame(width: size, height: size, alignment: .bottom)
        }
    }

    @ViewBuilder private func sprite(at t: Double, motion: PetMotion) -> some View {
        if let active = activeClip(at: t), let frames = variantFrames(for: active.clip, name: active.name, at: t) {
            let frame = frames[frameIndex(active.clip, frameCount: frames.count, at: t)]
            // Keep headroom inside the stable view bounds for hop/working
            // offsets so tall sprites do not jump outside their window.
            let scale = (size * 0.88) / max(species.referenceHeight, 1)
            Image(nsImage: frame)
                .resizable()
                .interpolation(.none)
                .frame(width: frame.size.width * scale, height: frame.size.height * scale)
                .rotationEffect(.degrees(motion.rotation), anchor: .bottom)
                .scaleEffect(x: motion.scaleX, y: motion.scaleY, anchor: .bottom)
                .offset(y: motion.offsetY)
        } else {
            Image(systemName: "pawprint.fill").font(.system(size: size * 0.4)).foregroundStyle(.secondary)
        }
    }

    private func activeClip(at t: Double) -> (name: String, clip: PMDAnim)? {
        let names = preferredAnimNames ?? PMDMoodMap.animNames(for: mood)
        let candidates = names.compactMap { name -> (String, PMDAnim)? in
            guard let clip = species.anim(name) else { return nil }
            return (name, clip)
        }
        if let selected = selectedCandidate(candidates, names: names, at: t) {
            return selected
        }
        if let first = species.anims.keys.sorted().first, let clip = species.anim(first) {
            return (first, clip)
        }
        return nil
    }

    private func selectedCandidate(
        _ candidates: [(name: String, clip: PMDAnim)],
        names: [String],
        at t: Double
    ) -> (name: String, clip: PMDAnim)? {
        guard !candidates.isEmpty else { return nil }
        guard candidates.count > 1 else { return candidates[0] }

        let nonIdle = candidates.filter { $0.name != "Idle" }
        let pool = mood == .idle || nonIdle.isEmpty ? candidates : nonIdle
        let bucket = Int((t / 2.8).rounded(.down))
        let seed = stableHash("\(species.dex)-\(mood)-\(names.joined(separator: ","))")
        let index = positiveModulo(seed &+ bucket &* 1_664_525, pool.count)
        return pool[index]
    }

    private func variantFrames(for clip: PMDAnim, name: String, at t: Double) -> [NSImage]? {
        let variants = clip.variants.filter { !$0.isEmpty }
        guard !variants.isEmpty else { return nil }
        guard variants.count > 1 else { return variants[0] }

        let loop = max(loopDuration(clip), 0.1)
        let loopIndex = Int((t / loop).rounded(.down))
        let seed = stableHash("\(species.dex)-\(name)")
        let index = positiveModulo(seed &+ loopIndex &* 1_103_515_245, variants.count)
        return variants[index]
    }

    /// Selects the active frame for time `t`, advancing through `durations`.
    private func frameIndex(_ clip: PMDAnim, frameCount count: Int, at t: Double) -> Int {
        let durations = clip.durations.isEmpty
            ? Array(repeating: 4, count: count)
            : Array(clip.durations.prefix(count))
        let total = durations.reduce(0, +)
        guard total > 0 else { return 0 }
        var remaining = t.truncatingRemainder(dividingBy: Double(total) * Self.unit)
        for (i, d) in durations.enumerated() {
            let span = Double(d) * Self.unit
            if remaining < span { return min(i, count - 1) }
            remaining -= span
        }
        return count - 1
    }

    private func loopDuration(_ clip: PMDAnim) -> Double {
        let count = max(clip.frames.count, 1)
        let durations = clip.durations.isEmpty
            ? Array(repeating: 4, count: count)
            : Array(clip.durations.prefix(count))
        return Double(durations.reduce(0, +)) * Self.unit
    }

    private func stableHash(_ text: String) -> Int {
        var hash = 2_166_136_261
        for byte in text.utf8 {
            hash = (hash ^ Int(byte)) &* 16_777_619
        }
        return hash
    }

    private func positiveModulo(_ value: Int, _ modulus: Int) -> Int {
        let remainder = value % modulus
        return remainder >= 0 ? remainder : remainder + modulus
    }
}
