import SwiftUI
import KabigonCore

/// Native macOS-style settings: a preferences-style toolbar of tabs over
/// grouped forms (dark).
struct SetupView: View {
    @ObservedObject private var model = SettingsModel.shared
    @ObservedObject private var pet = PetController.shared
    var onClose: () -> Void

    enum Tab { case general, reminders, pet }
    @State private var tab: Tab = .pet

    init(initialTab: Tab = .pet, onClose: @escaping () -> Void) {
        self.onClose = onClose
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            Group {
                switch tab {
                case .general:
                    GeneralTab(model: model, pet: pet)
                case .reminders:
                    RemindersTab()
                case .pet:
                    PetTab(pet: pet)
                }
            }
        }
        .frame(width: 560, height: 600)
        .preferredColorScheme(.dark)
        .noFocusRing()
        .onAppear { model.refresh() }
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            TabButton(icon: "pokeball", label: "Pokemon", selected: tab == .pet) { tab = .pet }
            TabButton(icon: "calendar.badge.clock", label: "Reminders", selected: tab == .reminders) { tab = .reminders }
            TabButton(icon: "gearshape.fill", label: "Setting", selected: tab == .general) { tab = .general }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

private struct TabButton: View {
    let icon: String
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if icon == "pokeball" {
                    PokeballIcon(selected: selected)
                        .frame(width: 19, height: 19)
                } else {
                    Image(systemName: icon).font(.system(size: 19))
                }
                Text(label).font(.system(size: 11))
            }
            .frame(width: 78, height: 48)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selected ? Color.systemAccent.opacity(0.22) : .clear))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(selected ? Color.systemAccent.opacity(0.55) : .clear, lineWidth: 1))
            .foregroundStyle(selected ? Color.systemAccent : Color.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PokeballIcon: View {
    let selected: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let lineHeight = max(2, size * 0.12)
            let buttonSize = size * 0.38
            let color = selected ? Color.systemAccent : Color.primary

            ZStack {
                Circle()
                    .fill(Color.white.opacity(selected ? 0.95 : 0.82))
                Circle()
                    .trim(from: 0, to: 0.5)
                    .fill(Color.red.opacity(selected ? 0.95 : 0.72))
                    .rotationEffect(.degrees(180))
                Rectangle()
                    .fill(color)
                    .frame(height: lineHeight)
                Circle()
                    .fill(Color.white)
                    .frame(width: buttonSize, height: buttonSize)
                    .overlay(Circle().strokeBorder(color, lineWidth: lineHeight))
                Circle()
                    .strokeBorder(color, lineWidth: lineHeight)
            }
            .frame(width: size, height: size)
        }
    }
}

private struct SoundRow: View {
    let title: String
    @Binding var enabled: Bool
    let customPath: String
    let onPlay: () -> Void
    let onUpload: () -> Void
    let onReset: () -> Void

    private var sourceLabel: String {
        customPath.isEmpty ? "Default" : (customPath as NSString).lastPathComponent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                ColorSwitch(isOn: $enabled)
            }
            HStack(spacing: 8) {
                Text(sourceLabel)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Spacer()
                Button { onPlay() } label: { Image(systemName: "play.circle") }.buttonStyle(.plain)
                Button("Upload…") { onUpload() }.controlSize(.small)
                if !customPath.isEmpty {
                    Button("Default") { onReset() }.controlSize(.small)
                }
            }
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)
        }
    }
}

// MARK: - General (merged setup + general)

private struct GeneralTab: View {
    @ObservedObject var model: SettingsModel
    @ObservedObject var pet: PetController
    @ObservedObject private var chat = ChatSettings.shared
    @ObservedObject private var sound = SoundSettings.shared
    // Local mirror of the system login-item state so the toggle re-renders
    // reliably (the SMAppService status isn't observable on its own).
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section("Launch") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at login")
                        Text("Kabigon starts automatically when you sign in.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    ColorSwitch(isOn: Binding(
                        get: { launchAtLogin },
                        set: { newValue in
                            LoginItem.setEnabled(newValue)
                            launchAtLogin = LoginItem.isEnabled
                        }))
}
            }

            Section("Notifications") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(notificationTitle)
                        Text(notificationDetail).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    notificationButton
                }
            }

            Section("Pet chat") {
                HStack {
                    Text("Show chat bubble")
                    Spacer()
                    ColorSwitch(isOn: $pet.showChat)
                }
                Picker("Messages", selection: $chat.source) {
                    Text("System").tag(ChatSettings.Source.system)
                    Text("Custom").tag(ChatSettings.Source.custom)
                }
                .pickerStyle(.segmented)
                if chat.source == .custom {
                    ForEach(ChatSettings.editableMoods, id: \.self) { mood in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(moodLabel(mood)).font(.caption).foregroundStyle(.secondary)
                            GrowingTextEditor(text: Binding(
                                get: { chat.text(for: mood) },
                                set: { chat.setText($0, for: mood) }
                            ))
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.16)))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.12)))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    HStack {
                        Text("One message per line; a random one is shown.")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset to defaults") { chat.resetToDefaults() }
                            .controlSize(.small)
                    }
                }
            }

            Section("Sounds") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pokémon cries")
                        Text("Play each Pokémon's voice when it speaks.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        PokemonCryPlayer.shared.play(dex: ProgressStore.shared.displayDex, force: true)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    .buttonStyle(.plain)
                    .disabled(!sound.pokemonCriesEnabled)
                    ColorSwitch(isOn: $sound.pokemonCriesEnabled)
                }
                SoundRow(title: "When an agent finishes",
                         enabled: $sound.doneEnabled,
                         customPath: sound.doneCustomPath,
                         onPlay: { sound.play(.done) },
                         onUpload: { sound.upload(for: .done) },
                         onReset: { sound.resetToDefault(.done) })
                SoundRow(title: "When an agent needs input",
                         enabled: $sound.waitingEnabled,
                         customPath: sound.waitingCustomPath,
                         onPlay: { sound.play(.waiting) },
                         onUpload: { sound.upload(for: .waiting) },
                         onReset: { sound.resetToDefault(.waiting) })
            }

            Section("Agent integrations") {
                ForEach(model.agents) { agent in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(agent.displayName)
                            if let note = agent.note {
                                Text(note).font(.caption).foregroundStyle(.secondary)
                            } else if model.isInstalled(agent.kind) {
                                Text("Hook installed").font(.caption).foregroundStyle(.green)
                            }
                        }
                        Spacer()
                        if agent.isSupported {
                            Button(model.isInstalled(agent.kind) ? "Remove" : "Install") {
                                model.toggleInstall(agent.kind)
                            }
                        } else {
                            Text("Coming soon").foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(versionLabel)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section {
                Button("Quit Kabigon") { NSApplication.shared.terminate(nil) }
            }
        }
        .formStyle(.grouped)
    }

    private func moodLabel(_ mood: PetMood) -> String {
        switch mood {
        case .working: return "Working"
        case .waiting: return "Waiting"
        case .done: return "Done"
        case .celebrate: return "Celebrate"
        case .idle: return "Idle"
        }
    }

    private var versionLabel: String {
        let info = Bundle.main.infoDictionary
        guard let version = info?["CFBundleShortVersionString"] as? String else {
            return "Development"
        }
        let build = info?["CFBundleVersion"] as? String
        guard let build, build != version else { return version }
        return "\(version) (\(build))"
    }

    private var notificationTitle: String {
        switch model.notificationState {
        case .enabled: return model.notificationsEnabled ? "Notifications on" : "Notifications muted"
        case .denied: return "Notifications denied"
        case .unavailable: return "Notifications unavailable"
        case .notDetermined: return "Enable notifications"
        }
    }

    private var notificationDetail: String {
        switch model.notificationState {
        case .unavailable: return "Available once installed as Kabigon.app"
        case .denied: return "Turn on in System Settings to get alerts"
        case .enabled: return model.notificationsEnabled
            ? "Alerts when an agent finishes or needs input"
            : "Muted, the toggle turns alerts back on"
        case .notDetermined: return "Alerts when an agent finishes or needs input"
        }
    }

    @ViewBuilder private var notificationButton: some View {
        switch model.notificationState {
        case .enabled:
            // Permission granted: an in-app toggle lets the user mute without
            // revoking the system permission.
            ColorSwitch(isOn: $model.notificationsEnabled)
        case .denied:
            Button("Open Settings") { model.openSystemNotificationSettings() }
        case .notDetermined:
            Button("Enable") { model.enableNotifications() }
        case .unavailable:
            EmptyView()
        }
    }
}

// MARK: - Reminders tab

private struct RemindersTab: View {
    @ObservedObject private var reminders = ReminderStore.shared
    private static let defaultMessage = "Time to drink water. Go pour yourself a glass."

    @State private var messages = defaultMessage
    @State private var mode: ReminderMode = .interval
    @State private var minutesText = "30"
    @State private var scheduledAt = Date().addingTimeInterval(30 * 60)

    private var parsedMinutes: Int {
        min(1440, max(1, Int(minutesText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 30))
    }

    private var canAdd: Bool {
        messages
            .components(separatedBy: .newlines)
            .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        Form {
            Section("New Reminder") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Messages")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        GrowingTextEditor(text: $messages)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.14)))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.10)))
                            .frame(minHeight: 92)
                        Text("One message per line")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("When")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $mode) {
                            Text("Every Period").tag(ReminderMode.interval)
                            Text("Specific time").tag(ReminderMode.scheduled)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        if mode == .interval {
                            HStack(spacing: 8) {
                                Text("Every")
                                TextField("", text: $minutesText)
                                    .frame(width: 72)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                Text("minutes")
                                Spacer()
                                Text("1-1440")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            DatePicker("Remind at", selection: $scheduledAt, displayedComponents: [.date, .hourAndMinute])
                        }
                    }

                    HStack {
                        Spacer()
                        Button {
                            reminders.add(messages: messages,
                                          mode: mode,
                                          minutes: parsedMinutes,
                                          scheduledAt: scheduledAt)
                            messages = Self.defaultMessage
                            minutesText = "\(parsedMinutes)"
                            scheduledAt = Date().addingTimeInterval(TimeInterval(parsedMinutes * 60))
                        } label: {
                            Label("Add Reminder", systemImage: "plus.circle.fill")
                        }
                        .disabled(!canAdd)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Active Reminders") {
                if reminders.reminders.isEmpty {
                    Text("No reminders yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(reminders.reminders) { reminder in
                        ReminderRow(reminder: reminder) {
                            reminders.remove(reminder)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: minutesText) { newValue in
            let filtered = newValue.filter(\.isNumber)
            if filtered != newValue { minutesText = filtered }
        }
    }
}

private struct ReminderRow: View {
    let reminder: ReminderItem
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.mode == .interval ? "repeat" : "calendar")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.systemAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.displayMessage)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(reminderSummary)
                    if reminder.messages.count > 1 {
                        Text("\(reminder.messages.count) messages")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .help("Remove reminder")
        }
        .padding(.vertical, 4)
    }

    private var reminderSummary: String {
        switch reminder.mode {
        case .interval:
            return "Every \(reminder.minutes) minute\(reminder.minutes == 1 ? "" : "s")"
        case .scheduled:
            return reminder.scheduledAt.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

// MARK: - Pet tab

private struct PetTab: View {
    @ObservedObject var pet: PetController
    @ObservedObject private var progress = ProgressStore.shared
    @ObservedObject private var pokedex = PokedexStore.shared
    @ObservedObject private var pmdStore = PMDPetStore.shared
    @ObservedObject private var encounters = EncounterManager.shared

    private var currentDex: Int { progress.displayDex }
    private var currentName: String {
        PokemonPokedex.name(for: currentDex) ?? "Pokémon #\(currentDex)"
    }

    var body: some View {
        Form {
            Section("Current Pokémon") {
                HStack(spacing: 14) {
                    currentPokemonPreview
                        .frame(width: 84, height: 84)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentName)
                            .font(.title3.weight(.semibold))

                        HStack(spacing: 6) {
                            Text(String(format: "#%03d", currentDex))
                            Text("Lv \(progress.level(for: currentDex))")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                        Text(PokemonDescriptions.text(for: currentDex))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .task(id: currentDex) {
                    await pmdStore.ensureLoaded(dex: currentDex)
                }
            }

            Section("Your Pokémon") {
                if pokedex.caughtCount == 0 {
                    Text("No Pokémon yet — choose a starter to get started!")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Each Pokémon levels independently. Evolution forms appear here once unlocked, and you can switch between any unlocked form.")
                        .font(.caption).foregroundStyle(.secondary)
                    CaughtPokemonGrid(activeDex: progress.displayDex) { dex in
                        progress.choosePokemon(dex: dex)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Automatic switching") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Change Pokémon automatically")
                        Text("Randomly picks another caught Pokémon at the selected interval.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ColorSwitch(isOn: $progress.autoSwitchEnabled)
                }

                Picker("Change every", selection: $progress.autoSwitchMinutes) {
                    Text("5 minutes").tag(5)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                }
                .disabled(!progress.autoSwitchEnabled)
            }

            Section("Testing") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shiny encounter")
                        Text("Immediately receive a random shiny Pokémon.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Test shiny encounter") {
                        encounters.triggerShinyEncounter()
                    }
                    .disabled(!progress.hasChosenStarter || encounters.isSpawning)
                }
            }

            Section("Size on screen") {
                HStack(spacing: 8) {
                    Slider(value: $pet.petPoint, in: PetController.minPoint...PetController.maxPoint)
                    Text("\(Int(pet.petPoint))")
                        .monospacedDigit().foregroundStyle(.secondary).fixedSize()
                    ForEach(PetController.presets, id: \.0) { preset in
                        Button(preset.0) { pet.animateSize(to: preset.1) }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder private var currentPokemonPreview: some View {
        if let species = pmdStore.loaded(dex: currentDex) {
            PMDSpriteView(species: species, mood: .idle, size: 78)
        } else if pmdStore.isLoading(dex: currentDex) {
            ProgressView().controlSize(.small)
        } else if pmdStore.didFail(dex: currentDex) {
            Button(action: { pmdStore.retry(dex: currentDex) }) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 28))
            }
            .buttonStyle(.plain)
            .help("Retry asset download")
        } else {
            Image(systemName: "pawprint.fill").font(.system(size: 40)).foregroundStyle(.secondary)
        }
    }
}

private enum PokemonDescriptions {
    static func text(for dex: Int) -> String {
        PokemonPokedex.description(for: dex) ?? "No Pokédex description is available."
    }
}

// MARK: - CaughtPokemonGrid

/// A grid of every Pokémon the player has caught, sorted by dex number.
/// Every species is selectable — tapping one switches the on-screen pet.
private struct CaughtPokemonGrid: View {
    /// The dex of the Pokémon currently shown on screen.
    let activeDex: Int
    /// Called with the tapped entry's dex number.
    let onSelect: (Int) -> Void

    @ObservedObject private var pokedex = PokedexStore.shared
    @ObservedObject private var pmdStore = PMDPetStore.shared
    @ObservedObject private var progress = ProgressStore.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    private var sortedEntries: [PokedexEntry] {
        pokedex.data.entries.sorted { $0.dex < $1.dex }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(sortedEntries) { entry in
                CaughtPokemonCard(
                    entry: entry,
                    loaded: pmdStore.loaded(dex: entry.dex),
                    isActive: entry.dex == activeDex,
                    level: progress.level(for: entry.dex),
                    isLoading: pmdStore.isLoading(dex: entry.dex),
                    didFail: pmdStore.didFail(dex: entry.dex),
                    onRetry: { pmdStore.retry(dex: entry.dex) }
                )
                .onTapGesture { onSelect(entry.dex) }
                .task(id: entry.dex) { await pmdStore.ensureLoaded(dex: entry.dex) }
            }
        }
    }
}

private struct CaughtPokemonCard: View {
    let entry: PokedexEntry
    let loaded: PMDLoadedSpecies?
    let isActive: Bool
    let level: Int
    let isLoading: Bool
    let didFail: Bool
    let onRetry: () -> Void

    private var sprite: NSImage? {
        loaded?.anim("Idle")?.frames.first
    }

    private var pokemonName: String {
        PokemonPokedex.name(for: entry.dex) ?? "#\(entry.dex)"
    }

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let sprite {
                    PMDThumbnailView(image: sprite, targetWidth: 34, maxHeight: 40)
                        .shinyVariant(entry.isShiny)
                } else if isLoading {
                    ProgressView().controlSize(.small)
                } else if didFail {
                    Button(action: onRetry) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    .help("Retry asset download")
                } else {
                    Image(systemName: "pawprint.fill").foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 44)

            Text(pokemonName)
                .font(.caption2).lineLimit(1)
                .foregroundStyle(isActive ? Color.systemAccent : .primary)

            Text("Lv \(level)")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(isActive ? Color.systemAccent.opacity(0.18) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .strokeBorder(
                isActive ? Color.systemAccent : Color.secondary.opacity(0.3),
                lineWidth: isActive ? 2 : 1))
        .overlay(alignment: .topLeading) {
            if entry.isShiny {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.yellow)
                    .padding(5)
                    .help("Shiny")
            }
        }
    }
}

// MARK: - Components

/// A single static sprite frame (no TimelineView), for grids where animating
/// every cell would be janky. Only the hero preview animates.
private struct StaticFrame: View {
    let image: NSImage?
    var size: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Image(systemName: "pawprint.fill").foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct PetPager: View {
    let packs: [ImagePetPack]
    let selectedID: String?
    let onSelect: (String) -> Void
    let onDelete: (ImagePetPack) -> Void
    @State private var page = 0

    private let perPage = 8

    var body: some View {
        let pageCount = max(1, Int(ceil(Double(packs.count) / Double(perPage))))
        let current = min(page, pageCount - 1)

        VStack(spacing: 10) {
            GeometryReader { geo in
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<pageCount, id: \.self) { p in
                        grid(for: p).frame(width: geo.size.width, alignment: .top)
                    }
                }
                .offset(x: -CGFloat(current) * geo.size.width)
                .animation(.easeInOut(duration: 0.28), value: current)
            }
            .frame(height: 188)
            .clipped()

            if pageCount > 1 {
                HStack(spacing: 14) {
                    arrow("chevron.left", enabled: current > 0) { page = max(0, current - 1) }
                    HStack(spacing: 5) {
                        ForEach(0..<pageCount, id: \.self) { i in
                            Circle()
                                .fill(i == current ? Color.systemAccent : .secondary.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                    }
                    arrow("chevron.right", enabled: current < pageCount - 1) { page = min(pageCount - 1, current + 1) }
                }
            }
        }
        .padding(.vertical, 4)
        .onChange(of: packs.count) { _ in page = 0 }
    }

    private func grid(for pageIndex: Int) -> some View {
        let slice = Array(packs.dropFirst(pageIndex * perPage).prefix(perPage))
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                         alignment: .leading, spacing: 12) {
            ForEach(slice) { pack in
                PetThumb(pack: pack, selected: selectedID == pack.id,
                         select: { onSelect(pack.id) },
                         onDelete: { onDelete(pack) })
            }
        }
    }

    private func arrow(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.secondary : Color.secondary.opacity(0.3))
        .disabled(!enabled)
    }
}

private struct PetThumb: View {
    let pack: ImagePetPack
    let selected: Bool
    let select: () -> Void
    var onDelete: (() -> Void)? = nil
    @State private var hovering = false

    var body: some View {
        Button(action: select) {
            VStack(spacing: 4) {
                StaticFrame(image: pack.clip(0).first, size: 48)
                    .frame(width: 56, height: 48)
                Text(pack.displayName).font(.caption).lineLimit(1).frame(width: 64)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 10).fill(selected ? Color.systemAccent.opacity(0.2) : .clear))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Color.systemAccent : .secondary.opacity(0.3), lineWidth: selected ? 2 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if hovering, let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white, .black.opacity(0.55))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }
        }
        .onHover { hovering = $0 }
    }
}

private struct AnimationPicker: View {
    let pack: ImagePetPack
    @ObservedObject private var store = PetBindingsStore.shared
    @State private var state: PetMood = .working
    @State private var hoveredClip: Int?

    private let states: [PetMood] = [.idle, .working, .waiting, .done, .celebrate]

    var body: some View {
        Picker("State", selection: $state) {
            ForEach(states, id: \.self) { Text(label($0)).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()

        Text("Hover a clip to preview it.")
            .font(.caption2).foregroundStyle(.secondary)

        let current = store.clipIndex(packId: pack.id, clipCount: pack.clipCount, mood: state)
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
            ForEach(0..<pack.clipCount, id: \.self) { i in
                Button {
                    store.setClip(i, mood: state, packId: pack.id, clipCount: pack.clipCount)
                } label: {
                    VStack(spacing: 3) {
                        Group {
                            if hoveredClip == i {
                                ImageSpriteView(frames: pack.clip(i), mood: .working, size: 44)
                            } else {
                                StaticFrame(image: pack.clip(i).first, size: 44)
                            }
                        }
                        .frame(width: 54, height: 44)
                        Text("Clip \(i + 1)").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 9).fill(i == current ? Color.systemAccent.opacity(0.2) : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(i == current ? Color.systemAccent : .secondary.opacity(0.25), lineWidth: i == current ? 2 : 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hoveredClip = $0 ? i : (hoveredClip == i ? nil : hoveredClip) }
            }
        }
        .padding(.vertical, 4)
    }

    private func label(_ mood: PetMood) -> String {
        switch mood {
        case .idle: return "Idle"
        case .working: return "Working"
        case .waiting: return "Waiting"
        case .done: return "Done"
        case .celebrate: return "Celebrate"
        }
    }
}
