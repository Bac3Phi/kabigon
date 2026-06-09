import SwiftUI
import AppKit
import KabigonCore

/// Rich menu bar popover: a blurred dark card with an arrow pointing at the
/// status item, a live agent list, and a footer bar.
struct MenuContentView: View {
    @ObservedObject private var daemon = AppDaemon.shared
    @ObservedObject private var petWindow = PetWindowController.shared
    @ObservedObject private var statusBar = StatusBarController.shared
    @ObservedObject private var pet = PetController.shared
    @ObservedObject private var progress = ProgressStore.shared
    @ObservedObject private var pokedex = PokedexStore.shared
    var dismiss: () -> Void

    /// Show agents that are doing something or just finished. Idle and merely
    /// `registered` (open but not working) sessions are hidden, so an idle
    /// terminal doesn't sit in the list; they reappear the moment they work.
    private var agents: [AgentSession] {
        daemon.sessions.filter { $0.state != .idle && $0.state != .registered }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if progress.hasChosenStarter {
                divider
                petStats
                levelUpTestRow
                pokedexRow
            }
            divider
            agentSection
            divider
            controls
            divider
            footer
        }
        .frame(width: 300)
        .background(.regularMaterial)
        .environment(\.colorScheme, .dark)
        .noFocusRing()
    }

    private var divider: some View { Divider().overlay(Color.white.opacity(0.08)) }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            KabigonLogoMark(iconSize: 28, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text("Kabigon").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(14)
    }

    private var subtitle: String {
        let total = agents.count
        if total == 0 { return "No agents running" }
        let running = agents.filter { $0.state == .working }.count
        let label = "\(total) agent\(total == 1 ? "" : "s")"
        return running > 0 ? "\(label) · \(running) running" : label
    }

    // MARK: Pet stats

    /// A compact strip naming the active Pokémon with its level and affection,
    /// so petting visibly pays off and the chosen species is identifiable.
    private var petStats: some View {
        HStack(spacing: 8) {
            Text(progress.displayName)
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
            Text("Lv \(progress.displayLevel)")
                .font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.55))
            Spacer()
            Label("\(progress.affection)", systemImage: "heart.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.pink)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    private var levelUpTestRow: some View {
        Button {
            progress.levelUpForTesting()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(Color.systemAccent).frame(width: 16)
                Text("Level up")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                Spacer()
                Text("Test")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(.white.opacity(0.10)))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(progress.displayLevel >= progress.config.maxLevel)
        .opacity(progress.displayLevel >= progress.config.maxLevel ? 0.45 : 1)
    }

    /// A row opening the Pokédex, with the caught count and a NEW badge when
    /// freshly discovered species are waiting to be viewed.
    private var pokedexRow: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                PokedexWindowController.shared.show()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .foregroundStyle(.white.opacity(0.8)).frame(width: 16)
                Text("Pokédex").font(.system(size: 13)).foregroundStyle(.white)
                Text("\(pokedex.caughtCount)/\(PokemonPokedex.count)")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                Spacer()
                if pokedex.newCount > 0 {
                    Text("\(pokedex.newCount) NEW")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule().fill(Color.systemAccent))
                        .foregroundStyle(.white)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Agents

    private var agentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionLabel("Agents")
                Spacer()
                if !agents.isEmpty {
                    Button("Clear all") { daemon.clearSessions() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.trailing, 14).padding(.top, 12).padding(.bottom, 6)
                }
            }
            if agents.isEmpty {
                Text("Nothing running right now.")
                    .font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 14).padding(.bottom, 12)
            } else {
                ForEach(agents) { session in
                    AgentRow(session: session, onClear: { daemon.removeSession(session.id) })
                }
                .padding(.bottom, 6)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold)).tracking(1.4)
            .foregroundStyle(.white.opacity(0.35))
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 6)
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 0) {
            controlRow(icon: "pawprint", label: "Show pet", isOn: $petWindow.isVisible)
            actionRow(icon: "arrow.triangle.2.circlepath.circle", label: "Change Pokémon") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    SettingsWindowController.shared.show(initialTab: .pet)
                }
            }
            controlRow(icon: "number", label: "Show count on menu bar", isOn: $statusBar.showCount)
            controlRow(icon: "bubble.left", label: "Show chat on menu bar", isOn: $statusBar.showChatOnMenuBar)
            sizeRow
        }
    }

    private var sizeRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .foregroundStyle(.white.opacity(0.8)).frame(width: 16)
            Text("Pet size").font(.system(size: 13)).foregroundStyle(.white)
            Slider(value: $pet.petPoint, in: PetController.minPoint...PetController.maxPoint)
                .controlSize(.mini)
                .tint(Color.systemAccent)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    private func controlRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(.white.opacity(0.8)).frame(width: 16)
            Text(label).font(.system(size: 13)).foregroundStyle(.white)
            Spacer()
            ColorSwitch(isOn: isOn)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    private func actionRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(.white.opacity(0.8)).frame(width: 16)
                Text(label).font(.system(size: 13)).foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            FooterButton(icon: "gearshape", label: "Settings") {
                dismiss()
                // Open after the popover finishes closing so the window
                // reliably comes to the front.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    SettingsWindowController.shared.show()
                }
            }
            FooterButton(icon: "arrow.triangle.2.circlepath", label: "Updates") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    UpdaterController.shared.checkForUpdates()
                }
            }
#if DEBUG
            FooterButton(icon: "ant", label: "Spawn") {
                EncounterManager.shared.triggerRandomEncounter()
            }
#endif
            Spacer()
            FooterButton(icon: "power", label: "Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

/// Per-agent colour and icon used to identify a session at a glance.
extension AgentKind {
    var tint: Color {
        switch self {
        case .claude: return .orange
        case .codex: return .green
        case .gemini: return .blue
        case .cursor: return .purple
        case .opencode: return .pink
        case .windsurf: return .teal
        case .augment: return Color(red: 0.18, green: 0.55, blue: 1.0)
        case .hermes: return .mint
        case .cli, .unknown: return .gray
        }
    }

    var symbol: String {
        switch self {
        case .claude: return "sparkle"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        case .gemini: return "diamond.fill"
        case .cursor: return "cursorarrow.rays"
        case .opencode: return "curlybraces"
        case .windsurf: return "wind"
        case .augment: return "wand.and.stars"
        case .hermes: return "bird.fill"
        case .cli: return "terminal"
        case .unknown: return "cpu"
        }
    }
}

private struct FooterButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
}

private struct AgentRow: View {
    let session: AgentSession
    var onClear: () -> Void = {}
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(dotColor).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(project).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                        .lineLimit(1).truncationMode(.tail)
                    agentBadge
                }
                Text(subtitle)
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1).truncationMode(.tail)
            }
            Spacer(minLength: 8)
            if hovering {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(timeString(now: context.date))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }

    /// A small coloured chip naming which agent this session belongs to.
    private var agentBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: session.agentKind.symbol).font(.system(size: 8, weight: .bold))
            Text(session.agentKind.displayName).font(.system(size: 9, weight: .semibold))
        }
        .padding(.horizontal, 5).padding(.vertical, 1)
        .background(Capsule().fill(session.agentKind.tint.opacity(0.22)))
        .foregroundStyle(session.agentKind.tint)
        .fixedSize()
    }

    private var project: String {
        session.project.map { ($0 as NSString).lastPathComponent } ?? session.id
    }

    /// The agent's context (waiting reason / running tool) when known, else its state.
    private var subtitle: String {
        if let message = session.message, !message.isEmpty { return message }
        return session.state.rawValue.capitalized
    }

    private var dotColor: Color {
        switch session.state {
        case .working, .registered: return .blue
        case .waiting: return .orange
        case .done: return .green
        case .idle: return .gray
        }
    }

    private func timeString(now: Date) -> String {
        switch session.state {
        case .done, .idle:
            return session.updatedAt.formatted(date: .omitted, time: .shortened)
        default:
            let s = max(0, Int(now.timeIntervalSince(session.stateSince)))
            return s < 60 ? "\(s)s" : "\(s / 60)m \(s % 60)s"
        }
    }
}
