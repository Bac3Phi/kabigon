import AppKit
import SwiftUI

/// Static PMD sprite thumbnail for dense grids. It trims transparent padding
/// before scaling so Pokemon with different source canvas sizes read similarly.
struct PMDThumbnailView: View {
    let image: NSImage
    var targetWidth: CGFloat
    var maxHeight: CGFloat

    var body: some View {
        let trimmed = PMDVisibleSpriteCache.shared.trimmedImage(for: image)
        let size = fittedSize(for: trimmed.size)

        Image(nsImage: trimmed)
            .resizable()
            .interpolation(.none)
            .frame(width: size.width, height: size.height)
    }

    private func fittedSize(for imageSize: NSSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGSize(width: targetWidth, height: maxHeight)
        }

        let scale = min(targetWidth / imageSize.width, maxHeight / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}

@MainActor
private final class PMDVisibleSpriteCache {
    static let shared = PMDVisibleSpriteCache()

    private let cache = NSCache<NSImage, NSImage>()

    func trimmedImage(for image: NSImage) -> NSImage {
        if let cached = cache.object(forKey: image) { return cached }
        let trimmed = image.trimmedToVisiblePixels() ?? image
        cache.setObject(trimmed, forKey: image)
        return trimmed
    }
}

private extension NSImage {
    func trimmedToVisiblePixels(alphaThreshold: UInt8 = 8) -> NSImage? {
        var proposed = CGRect(origin: .zero, size: size)
        guard let cg = cgImage(forProposedRect: &proposed, context: nil, hints: nil),
              let bounds = cg.visibleBounds(alphaThreshold: alphaThreshold),
              let cropped = cg.cropping(to: bounds)
        else { return nil }

        return NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
    }
}

private extension CGImage {
    func visibleBounds(alphaThreshold: UInt8) -> CGRect? {
        let width = self.width
        let height = self.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[y * bytesPerRow + x * bytesPerPixel + 3]
                guard alpha > alphaThreshold else { continue }
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }
}
