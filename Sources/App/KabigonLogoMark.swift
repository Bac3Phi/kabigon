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
                Image("KabigonLogo", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .padding(iconSize * 0.12)
                    .accessibilityLabel("Kabigon")
            }
    }
}
