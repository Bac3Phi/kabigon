import SwiftUI
import KabigonCore

/// The collectible Pokédex: every supported species in dex order. Uncaught species
/// show a "?", caught ones show their sprite, name, and level, with a NEW badge
/// on freshly discovered Pokémon until the player views them.
struct PokedexView: View {
    @ObservedObject private var pokedex = PokedexStore.shared
    @ObservedObject private var pmdStore = PMDPetStore.shared
    var onClose: () -> Void

    /// NEW dexes captured when the view opened, so the badges stay visible this
    /// session even though opening clears the live flags (resetting the menu
    /// bar badge).
    @State private var newlySeen: Set<Int> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.08))
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(PokemonPokedex.dexRange, id: \.self) { dex in
                        let entry = pokedex.entry(dex)
                        PokedexCell(dex: dex, entry: entry,
                                    loaded: pmdStore.loaded(dex: dex),
                                    showNew: newlySeen.contains(dex),
                                    isLoading: pmdStore.isLoading(dex: dex),
                                    didFail: pmdStore.didFail(dex: dex),
                                    onRetry: { pmdStore.retry(dex: dex) })
                            .task(id: dex) {
                                if entry != nil { await pmdStore.ensureLoaded(dex: dex) }
                            }
                    }
                }
                .padding(14)
            }
        }
        .frame(width: 560, height: 600)
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .noFocusRing()
        .onAppear {
            newlySeen = Set(pokedex.data.entries.filter(\.isNew).map(\.dex))
            pokedex.clearAllNew()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pokédex").font(.title2.bold()).foregroundStyle(.white)
                Text("\(pokedex.caughtCount) / \(PokemonPokedex.count) caught")
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Button("Done", action: onClose)
                .keyboardShortcut(.defaultAction)
        }
        .padding(14)
    }
}

/// One Pokédex slot: a sprite + name + level when caught, or a silhouette "?"
/// placeholder when still undiscovered.
private struct PokedexCell: View {
    let dex: Int
    let entry: PokedexEntry?
    let loaded: PMDLoadedSpecies?
    let showNew: Bool
    let isLoading: Bool
    let didFail: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if entry != nil, let image = idleFrame {
                    Image(nsImage: image)
                        .resizable().interpolation(.none).scaledToFit()
                } else if entry != nil, isLoading {
                    ProgressView().controlSize(.small)
                } else if entry != nil, didFail {
                    Button(action: onRetry) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .help("Retry asset download")
                } else if entry != nil {
                    Image(systemName: "hourglass")
                        .font(.system(size: 18)).foregroundStyle(.white.opacity(0.4))
                } else {
                    Text("?")
                        .font(.system(size: 26, weight: .bold)).foregroundStyle(.white.opacity(0.22))
                }
            }
            .frame(width: 60, height: 56)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(entry == nil ? .white.opacity(0.4) : .white)
                .lineLimit(1)
            Text(entry.map { "Lv \($0.level)" } ?? " ")
                .font(.system(size: 9)).foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(entry == nil ? 0.03 : 0.06)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.08)))
        .overlay(alignment: .topTrailing) {
            if showNew {
                Text("NEW")
                    .font(.system(size: 8, weight: .heavy))
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(Capsule().fill(Color.systemAccent))
                    .foregroundStyle(.white)
                    .offset(x: 4, y: -4)
            }
        }
    }

    /// The first idle frame (or any first frame) used as a static thumbnail.
    private var idleFrame: NSImage? {
        loaded?.anims["Idle"]?.frames.first ?? loaded?.anims.values.first?.frames.first
    }

    private var label: String {
        if entry != nil, let name = PokemonPokedex.name(for: dex) { return name }
        return String(format: "#%03d", dex)
    }
}
