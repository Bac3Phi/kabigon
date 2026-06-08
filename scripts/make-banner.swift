import AppKit

// Renders a 1280x640 README banner at 2x (2560x1280) for crispness.
let scale: CGFloat = 2
let W: CGFloat = 1280, H: CGFloat = 640
let px = NSSize(width: W * scale, height: H * scale)

let image = NSImage(size: px)
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
ctx.scaleBy(x: scale, y: scale)

// Background gradient (navy -> indigo) with a soft glow.
let bg = NSGradient(colors: [
    NSColor(srgbRed: 0.05, green: 0.07, blue: 0.16, alpha: 1),
    NSColor(srgbRed: 0.10, green: 0.08, blue: 0.24, alpha: 1),
])
bg?.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -60)
let glow = NSGradient(colors: [
    NSColor(srgbRed: 0.45, green: 0.40, blue: 0.98, alpha: 0.30),
    NSColor.clear,
])
glow?.draw(in: NSRect(x: W - 520, y: H - 520, width: 700, height: 700), relativeCenterPosition: .zero)

// App icon.
let iconRect = NSRect(x: 90, y: H/2 - 70, width: 140, height: 140)
if let icon = NSImage(contentsOfFile: "assets/icon.png") {
    icon.draw(in: iconRect)
}

func draw(_ s: String, x: CGFloat, y: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
    let a: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ]
    NSAttributedString(string: s, attributes: a).draw(at: NSPoint(x: x, y: y))
}

draw("Kabigon", x: 270, y: H/2 + 28, size: 76, weight: .bold, color: .white)
draw("A desktop pet that watches your AI coding agents.", x: 274, y: H/2 - 14,
     size: 26, weight: .regular, color: NSColor(white: 1, alpha: 0.78))
draw("Claude Code · Codex · Gemini CLI   —   macOS menu bar", x: 274, y: H/2 - 52,
     size: 18, weight: .medium, color: NSColor(srgbRed: 0.62, green: 0.62, blue: 0.95, alpha: 1))

image.unlockFocus()

guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/banner.png"
try png.write(to: URL(fileURLWithPath: out))
print("wrote \(out) \(Int(px.width))x\(Int(px.height))")
