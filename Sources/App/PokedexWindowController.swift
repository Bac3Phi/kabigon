import AppKit
import SwiftUI

/// Owns the Pokédex window, opened from the menu bar. Mirrors the Settings
/// window: shows a Dock icon while open and drops back to a menu bar accessory
/// when closed.
@MainActor
final class PokedexWindowController: NSObject, NSWindowDelegate {
    static let shared = PokedexWindowController()

    private var window: NSWindow?

    func show() {
        // Rebuild so it always opens fresh (scrolled to top, badges recomputed).
        window?.close()
        window = nil

        NSApp.setActivationPolicy(.regular)

        let host = NSHostingView(rootView: PokedexView(onClose: { [weak self] in
            self?.window?.close()
        }))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false
        )
        window.title = "Pokédex"
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.center()
        self.window = window

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
