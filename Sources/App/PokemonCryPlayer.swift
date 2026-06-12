import AppKit
import KabigonCore

/// Downloads, caches, and plays the active species' short cry when the pet speaks.
@MainActor
final class PokemonCryPlayer {
    static let shared = PokemonCryPlayer()

    private static let remoteRoot = "https://play.pokemonshowdown.com/audio/cries"
    private static let minimumInterval: TimeInterval = 0.7

    private var sound: NSSound?
    private var lastPlayedAt = Date.distantPast
    private var requestID = UUID()
    private var downloads: [Int: Task<URL?, Never>] = [:]

    private var cacheDir: URL {
        URL(fileURLWithPath: KabigonPaths.baseDir).appendingPathComponent("cries")
    }

    func play(dex: Int, force: Bool = false) {
        guard SoundSettings.shared.pokemonCriesEnabled,
              PokemonPokedex.dexRange.contains(dex) else { return }
        guard force || Date().timeIntervalSince(lastPlayedAt) >= Self.minimumInterval else { return }

        let id = UUID()
        requestID = id
        if let url = cachedURL(dex: dex) {
            play(url: url)
            return
        }

        let startedAt = Date()
        Task { [weak self] in
            guard let self, let url = await self.download(dex: dex) else { return }
            guard self.requestID == id,
                  SoundSettings.shared.pokemonCriesEnabled,
                  Date().timeIntervalSince(startedAt) < 4 else { return }
            self.play(url: url)
        }
    }

    func preload(dex: Int) {
        guard SoundSettings.shared.pokemonCriesEnabled, cachedURL(dex: dex) == nil else { return }
        Task { [weak self] in _ = await self?.download(dex: dex) }
    }

    private func play(url: URL) {
        sound?.stop()
        sound = NSSound(contentsOf: url, byReference: false)
        sound?.volume = 0.55
        sound?.play()
        lastPlayedAt = Date()
    }

    private func cachedURL(dex: Int) -> URL? {
        let url = cacheDir.appendingPathComponent("\(dex).mp3")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func download(dex: Int) async -> URL? {
        if let cached = cachedURL(dex: dex) { return cached }
        if let existing = downloads[dex] { return await existing.value }

        let destination = cacheDir.appendingPathComponent("\(dex).mp3")
        let slug = Self.slug(dex: dex)
        let task = Task<URL?, Never> {
            guard let remote = URL(string: "\(Self.remoteRoot)/\(slug).mp3"),
                  let (data, response) = try? await URLSession.shared.data(from: remote),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  !data.isEmpty else { return nil }
            do {
                try FileManager.default.createDirectory(
                    at: destination.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try data.write(to: destination, options: .atomic)
                return destination
            } catch {
                return nil
            }
        }
        downloads[dex] = task
        let result = await task.value
        downloads[dex] = nil
        return result
    }

    private static func slug(dex: Int) -> String {
        switch dex {
        case 29: return "nidoranf"
        case 32: return "nidoranm"
        default:
            return (PokemonPokedex.name(for: dex) ?? "")
                .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
                .lowercased()
                .filter { $0.isLetter || $0.isNumber }
        }
    }
}
