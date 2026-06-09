import SwiftUI
import KabigonCore

/// First-launch welcome: choose a starter Pokémon and connect an agent.
struct OnboardingView: View {
    @ObservedObject private var model = SettingsModel.shared
    @ObservedObject private var pmdStore = PMDPetStore.shared
    var onFinish: () -> Void

    /// The dex number the player has highlighted (defaults to Bulbasaur).
    @State private var pickedDex: Int = PMDCatalog.starterDexes.first ?? 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                starterStep
                agentStep
                notificationStep
                HStack {
                    Spacer()
                    Button("Get started") {
                        ProgressStore.shared.chooseStarter(pickedDex)
                        onFinish()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.systemAccent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(EdgeInsets(top: 40, leading: 28, bottom: 28, trailing: 28))
        }
        .frame(width: 560, height: 640)
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .noFocusRing()
        .onAppear {
            model.refresh()
            PMDCatalog.starterDexes.forEach { pmdStore.preload($0) }
            Task { @MainActor in
                for dex in PMDCatalog.starterDexes {
                    await pmdStore.ensureLoaded(dex: dex)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.systemAccent).frame(width: 34, height: 34)
                    .overlay(Image(systemName: "pawprint.fill").font(.system(size: 17)).foregroundStyle(.white))
                Text("Welcome to Kabigon").font(.title2.bold()).foregroundStyle(.white)
            }
            Text("A desktop pet that watches your AI coding agents. Two quick steps to get going.")
                .font(.callout).foregroundStyle(.white.opacity(0.7))
        }
    }

    // Step 1: pick a Pokémon
    private var starterStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepLabel(1, "Choose your Pokémon")
            Text("Starters evolve as your agents work. Pick one to begin!")
                .font(.caption).foregroundStyle(.white.opacity(0.6))
            SpeciesPickerGrid(selectedDex: pickedDex) { pickedDex = $0 }
        }
        .themedCard()
    }

    // Step 2: agent
    private var agentStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepLabel(2, "Connect an agent")
            Text("Install a hook so Kabigon can see when an agent works, finishes, or needs you.")
                .font(.caption).foregroundStyle(.white.opacity(0.6))
            ForEach(model.agents) { agent in
                HStack {
                    Text(agent.displayName).foregroundStyle(.white)
                    if model.isInstalled(agent.kind) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                    }
                    Spacer()
                    Button(model.isInstalled(agent.kind) ? "Connected" : "Connect") {
                        model.toggleInstall(agent.kind)
                    }
                    .disabled(model.isInstalled(agent.kind))
                }
            }
        }
        .themedCard()
    }

    // Step 3: notifications (optional)
    private var notificationStep: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Enable notifications").foregroundStyle(.white)
                Text("Get alerted when an agent finishes or needs input.")
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            switch model.notificationState {
            case .enabled: Label("On", systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
            case .denied: Button("Open Settings") { model.openSystemNotificationSettings() }
            case .notDetermined: Button("Enable") { model.enableNotifications() }
            case .unavailable: Text("—").foregroundStyle(.white.opacity(0.4))
            }
        }
        .themedCard()
    }

    private func stepLabel(_ n: Int, _ title: String) -> some View {
        HStack(spacing: 8) {
            Text("\(n)")
                .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.systemAccent))
            Text(title).font(.headline).foregroundStyle(.white)
        }
    }
}

/// A reusable grid of starter species.
struct SpeciesPickerGrid: View {
    let selectedDex: Int
    let onSelect: (Int) -> Void
    @ObservedObject private var pmdStore = PMDPetStore.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(PMDCatalog.starterDexes, id: \.self) { dex in
                let species = PMDCatalog.species(dex: dex)
                SpeciesCard(
                    dex: dex,
                    species: species,
                    loaded: pmdStore.loaded(dex: dex),
                    isLoading: pmdStore.isLoading(dex: dex),
                    didFail: pmdStore.didFail(dex: dex),
                    isSelected: selectedDex == dex
                )
                .onTapGesture { onSelect(dex) }
            }
        }
        .onAppear { PMDCatalog.starterDexes.forEach { pmdStore.preload($0) } }
        .task {
            for dex in PMDCatalog.starterDexes {
                await pmdStore.ensureLoaded(dex: dex)
            }
        }
    }
}

/// One selectable species card shown in the picker grid.
struct SpeciesCard: View {
    let dex: Int
    let species: PMDSpecies?
    let loaded: PMDLoadedSpecies?
    let isLoading: Bool
    let didFail: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let loaded {
                    PMDSpriteView(species: loaded, mood: .idle, size: 72)
                } else if isLoading {
                    ProgressView().controlSize(.small)
                } else if didFail {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24)).foregroundStyle(.yellow.opacity(0.8))
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 28)).foregroundStyle(.white.opacity(0.3))
                }
            }
            .frame(width: 80, height: 80)

            Text(species?.name ?? "???")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.systemAccent.opacity(0.25) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isSelected ? Color.systemAccent : Color.white.opacity(0.1), lineWidth: 1.5)
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
