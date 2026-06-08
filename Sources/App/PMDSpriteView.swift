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
        if let clip = activeClip, !clip.frames.isEmpty {
            let frame = clip.frames[frameIndex(clip, at: t)]
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

    private var activeClip: PMDAnim? {
        if let preferredAnimNames {
            for name in preferredAnimNames {
                if let clip = species.anim(name) { return clip }
            }
        }
        return PMDMoodMap.anim(for: mood, in: species)
    }

    /// Selects the active frame for time `t`, advancing through `durations`.
    private func frameIndex(_ clip: PMDAnim, at t: Double) -> Int {
        let count = clip.frames.count
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
}
