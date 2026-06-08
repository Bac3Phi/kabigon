import Foundation
import KabigonCore

/// Owns the live session state inside the running app: starts the socket
/// server, drains any queued events on launch, applies incoming events and
/// prunes stale ones, and publishes a display-ordered list to the UI.
///
/// All `SessionStore` access is confined to the main actor.
@MainActor
final class AppDaemon: ObservableObject {
    static let shared = AppDaemon()

    @Published private(set) var sessions: [AgentSession] = []

    private let store = SessionStore()
    private let server = EventSocketServer(path: KabigonPaths.socketPath)
    private var pruneTimer: Timer?

    func start() {
        try? FileManager.default.createDirectory(
            atPath: KabigonPaths.baseDir, withIntermediateDirectories: true
        )

        // Replay queued events with their original timestamps (not "now"), so
        // sessions that ended while the app was closed look stale and get
        // pruned immediately instead of resurrecting as "working".
        EventSocketServer.drainQueue(directory: KabigonPaths.queueDir) { [store] event in
            store.apply(event, now: event.timestamp)
        }
        store.prune(now: Date())
        refresh()

        try? server.start { event in
            Task { @MainActor [weak self] in self?.ingest(event) }
        }

        pruneTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task { @MainActor [weak self] in self?.prune() }
        }
    }

    /// Clears the tracked sessions (e.g. after disconnecting an integration).
    func clearSessions() {
        store.clear()
        refresh()
    }

    /// Dismisses a single session (e.g. a stuck agent).
    func removeSession(_ id: String) {
        store.remove(id: id)
        refresh()
    }

    private func ingest(_ event: AgentEvent) {
        let before = store.session(id: event.sessionId)?.state
        if let updated = store.apply(event, now: Date()) {
            notifyIfNeeded(before: before, session: updated)
            awardXPIfNeeded(before: before, after: updated.state)
        }
        refresh()
    }

    private func awardXPIfNeeded(before: AgentState?, after: AgentState) {
        guard after != before else { return }
        let cfg = ProgressStore.shared.config
        switch after {
        case .done where before != .done:
            ProgressStore.shared.addXP(cfg.xpPerDone)
        case _ where before == .waiting && after != .waiting:
            ProgressStore.shared.addXP(cfg.xpPerWaitingResolved)
        default:
            break
        }
    }

    private func notifyIfNeeded(before: AgentState?, session: AgentSession) {
        guard session.state != before else { return }
        let project = session.project.map { ($0 as NSString).lastPathComponent } ?? session.id
        let agent = session.agentKind.displayName
        switch session.state {
        case .waiting:
            NotificationManager.shared.notify(
                title: "\(project) needs input", body: session.message ?? "\(agent) is waiting for you")
            SoundSettings.shared.play(.waiting)
        case .done:
            NotificationManager.shared.notify(
                title: "\(project) finished", body: "\(agent) completed its turn")
            SoundSettings.shared.play(.done)
        default:
            break
        }
    }

    private func prune() {
        store.prune(now: Date())
        refresh()
    }

    private func refresh() {
        sessions = store.sorted
        PetController.shared.update(sessions: sessions)
        StatusBarController.shared.updateStatus(sessions)
    }
}
