import SwiftUI
import AppKit

struct KabigonLogoMark: View {
    var iconSize: CGFloat
    var cornerRadius: CGFloat
    var background: Color = Theme.accent

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(background)
            .frame(width: iconSize, height: iconSize)
            .overlay {
                Image(nsImage: Self.logoImage)
                    .resizable()
                    .scaledToFit()
                    .padding(iconSize * 0.12)
                    .accessibilityLabel("Kabigon")
            }
    }

    private static var logoImage: NSImage {
        NSImage(named: "KabigonLogo")
            ?? Bundle.main.url(forResource: "KabigonLogo", withExtension: "png").flatMap(NSImage.init(contentsOf:))
            ?? NSImage(named: "AppIcon")
            ?? NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Kabigon")
            ?? NSImage(size: NSSize(width: 18, height: 18))
    }
}
