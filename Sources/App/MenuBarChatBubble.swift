import AppKit
import SwiftUI

/// A small speech bubble with an upward tail, dropped from the menu bar icon.
struct MenuBarChatBubble: View {
    let text: String
    var portrait: NSImage? = nil
    var isShiny: Bool = false
    var maxWidth: CGFloat = 320

    private let font = NSFont.systemFont(ofSize: 12, weight: .medium)

    private var portraitWidth: CGFloat {
        portrait == nil ? 0 : 28
    }

    private var textWidth: CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    private var contentWidth: CGFloat {
        min(maxWidth, max(1, textWidth + portraitWidth))
    }

    private var maxTextWidth: CGFloat {
        max(1, contentWidth - portraitWidth)
    }

    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(.regularMaterial)
                .frame(width: 14, height: 7)
            HStack(alignment: .top, spacing: 6) {
                if let portrait {
                    Image(nsImage: portrait)
                        .resizable().interpolation(.none).scaledToFit()
                        .frame(width: 22, height: 22)
                        .shinyVariant(isShiny)
                }
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .frame(width: maxTextWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: contentWidth, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1))
        }
        .environment(\.colorScheme, .dark)
        .padding(6)
        .fixedSize()
    }
}

/// Upward-pointing triangle (apex at top).
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
