import AppKit
import SwiftUI
import KabigonCore

/// Owns the menu bar status item and a native `NSPopover` (the pattern used by
/// polished menu bar apps): smooth open/close animation, a real arrow pointing
/// at the icon, and transient auto-dismiss on outside clicks.
@MainActor
final class StatusBarController: NSObject, ObservableObject {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var lastSessions: [AgentSession] = []

    /// Whether to show the agent count next to the menu bar icon.
    @Published var showCount: Bool {
        didSet {
            UserDefaults.standard.set(showCount, forKey: "agentpet.showCount")
            updateStatus(lastSessions)
        }
    }
    /// Whether to show the pet's chat line next to the menu bar icon (default off).
    @Published var showChatOnMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showChatOnMenuBar, forKey: "agentpet.showChatMenuBar")
            updateStatus(lastSessions)
        }
    }

    override init() {
        showCount = (UserDefaults.standard.object(forKey: "agentpet.showCount") as? Bool) ?? true
        showChatOnMenuBar = (UserDefaults.standard.object(forKey: "agentpet.showChatMenuBar") as? Bool) ?? false
        super.init()
    }

    /// Recomputes the menu bar title (called when the chat line changes).
    func refreshTitle() { updateStatus(lastSessions) }

    func start() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = Self.menuBarImage(count: nil, waiting: false)
        item.button?.imagePosition = .imageLeading
        item.button?.target = self
        item.button?.action = #selector(toggle)
        statusItem = item

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.appearance = NSAppearance(named: .darkAqua)
        let host = NSHostingController(rootView: MenuContentView(dismiss: { [weak self] in
            self?.popover.performClose(nil)
        }))
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
    }

    /// Closes the popover when the user clicks anywhere outside it (including
    /// other apps / the desktop), which a transient popover can miss for a
    /// non-activating menu bar app.
    private var outsideClickMonitor: Any?

    @objc private func toggle() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    /// Reflects live agent state in the menu bar: a count of running agents, or
    /// an orange count when some need input, so it reads at a glance.
    func updateStatus(_ sessions: [AgentSession]) {
        lastSessions = sessions
        guard let button = statusItem?.button else { return }
        let active = sessions.filter { $0.state != .idle }
        let waiting = active.filter { $0.state == .waiting }.count
        // `registered` (agent open but idle) doesn't count as running, so just
        // opening an agent doesn't inflate the menu bar count.
        let running = active.filter { $0.state == .working }.count

        let hasAgents = waiting > 0 || running > 0

        button.title = ""
        if showCount, hasAgents {
            let count = waiting > 0 ? waiting : running
            button.image = Self.menuBarImage(count: count, waiting: waiting > 0)
        } else {
            button.image = Self.menuBarImage(count: nil, waiting: false)
        }

        refreshChatBubble()
    }

    /// Builds the menu bar image: the app logo alone, or logo plus a count laid out
    /// as a centered row (both centered vertically by their bounding boxes, so the
    /// digit never sits high or low relative to the icon).
    private static func menuBarImage(count: Int?, waiting: Bool) -> NSImage? {
        let base = NSImage(named: "AppIcon")
            ?? NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Kabigon")
        guard let base else { return nil }
        let iconSize = NSSize(width: 18, height: 18)

        guard let count else {
            let img = NSImage(size: iconSize)
            img.lockFocus()
            base.draw(in: NSRect(origin: .zero, size: iconSize))
            if waiting {
                NSColor.systemOrange.set()
                NSRect(origin: .zero, size: iconSize).fill(using: .sourceAtop)
            }
            img.unlockFocus()
            img.isTemplate = false
            return img
        }

        let font = NSFont.systemFont(ofSize: 13, weight: .bold)
        let text = "\(count)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: waiting ? NSColor.systemOrange : NSColor.labelColor,
        ]
        let textSize = text.size(withAttributes: attrs)
        let gap: CGFloat = 3
        let w = ceil(iconSize.width + gap + textSize.width)
        let h = ceil(max(iconSize.height, textSize.height))

        let img = NSImage(size: NSSize(width: w, height: h))
        img.lockFocus()
        base.draw(in: NSRect(x: 0, y: (h - iconSize.height) / 2, width: iconSize.width, height: iconSize.height))
        text.draw(at: NSPoint(x: iconSize.width + gap, y: (h - textSize.height) / 2), withAttributes: attrs)
        img.unlockFocus()
        img.isTemplate = false
        return img
    }

    // MARK: - Chat bubble dropping from the menu bar

    private var chatPanel: NSPanel?
    private var chatHideTimer: Timer?
    private var lastShownChat = ""

    private func refreshChatBubble() {
        let chat = PetController.shared.chatLine
        guard showChatOnMenuBar, !chat.isEmpty else {
            hideChatBubble()
            return
        }
        guard chat != lastShownChat else { return }
        lastShownChat = chat
        showChatBubble(chat)
    }

    private func showChatBubble(_ text: String) {
        guard let button = statusItem?.button, let buttonWindow = button.window else { return }

        let dex = ProgressStore.shared.displayDex
        let species = PMDPetStore.shared.loaded(dex: dex)
        let portrait = species?.portrait(PetController.shared.emotion.portraitName)
            ?? species?.portrait("Normal")
        let isShiny = PokedexStore.shared.entry(dex)?.isShiny ?? false
        let host = NSHostingView(rootView: MenuBarChatBubble(
            text: text,
            portrait: portrait,
            isShiny: isShiny
        ))
        host.setFrameSize(host.fittingSize)
        let size = host.fittingSize

        let panel = chatPanel ?? {
            let p = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
            p.level = .popUpMenu
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.ignoresMouseEvents = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            chatPanel = p
            return p
        }()
        panel.contentView = host
        panel.setContentSize(size)

        let frame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let originX = frame.midX - size.width / 2
        panel.setFrameOrigin(NSPoint(x: originX, y: frame.minY - size.height + 2))
        panel.orderFrontRegardless()

        chatHideTimer?.invalidate()
        chatHideTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
            Task { @MainActor [weak self] in self?.hideChatBubble() }
        }
    }

    private func hideChatBubble() {
        chatHideTimer?.invalidate()
        chatPanel?.orderOut(nil)
        lastShownChat = ""
    }

    /// Shows the same popover anchored to an arbitrary view (e.g. the floating
    /// pet on right-click).
    func showPopover(relativeTo rect: NSRect, of view: NSView, edge: NSRectEdge) {
        if popover.isShown { popover.performClose(nil) }
        popover.show(relativeTo: rect, of: view, preferredEdge: edge)
    }
}

extension StatusBarController: NSPopoverDelegate {
    func popoverDidShow(_ notification: Notification) {
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.popover.performClose(nil)
        }
    }

    func popoverDidClose(_ notification: Notification) {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
}
