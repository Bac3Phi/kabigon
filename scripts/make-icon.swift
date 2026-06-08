import AppKit

// Renders a 1024x1024 Kabigon icon inspired by the provided logo.
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))

func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
    NSPoint(x: x * size, y: y * size)
}

func path(_ points: [NSPoint], close: Bool = true) -> NSBezierPath {
    let path = NSBezierPath()
    guard let first = points.first else { return path }
    path.move(to: first)
    for point in points.dropFirst() { path.line(to: point) }
    if close { path.close() }
    return path
}

image.lockFocus()
NSColor.clear.set()
NSRect(x: 0, y: 0, width: size, height: size).fill()

// Outer blue head with cat-like ears.
let head = NSBezierPath()
head.move(to: p(0.50, 0.05))
head.curve(to: p(0.06, 0.34), controlPoint1: p(0.25, 0.05), controlPoint2: p(0.06, 0.16))
head.curve(to: p(0.08, 0.92), controlPoint1: p(0.00, 0.54), controlPoint2: p(0.01, 0.77))
head.curve(to: p(0.26, 0.82), controlPoint1: p(0.15, 0.93), controlPoint2: p(0.23, 0.89))
head.curve(to: p(0.50, 0.90), controlPoint1: p(0.36, 0.90), controlPoint2: p(0.43, 0.94))
head.curve(to: p(0.74, 0.82), controlPoint1: p(0.57, 0.94), controlPoint2: p(0.64, 0.90))
head.curve(to: p(0.92, 0.92), controlPoint1: p(0.77, 0.89), controlPoint2: p(0.85, 0.93))
head.curve(to: p(0.94, 0.34), controlPoint1: p(0.99, 0.77), controlPoint2: p(1.00, 0.54))
head.curve(to: p(0.50, 0.05), controlPoint1: p(0.94, 0.16), controlPoint2: p(0.75, 0.05))
head.close()
NSColor(srgbRed: 0.10, green: 0.56, blue: 0.90, alpha: 1).setFill()
head.fill()

// Subtle darker blue lower band and ears.
let band = NSBezierPath()
band.move(to: p(0.07, 0.36))
band.curve(to: p(0.39, 0.70), controlPoint1: p(0.06, 0.56), controlPoint2: p(0.20, 0.69))
band.curve(to: p(0.50, 0.58), controlPoint1: p(0.43, 0.66), controlPoint2: p(0.47, 0.62))
band.curve(to: p(0.61, 0.70), controlPoint1: p(0.53, 0.62), controlPoint2: p(0.57, 0.66))
band.curve(to: p(0.93, 0.36), controlPoint1: p(0.80, 0.69), controlPoint2: p(0.94, 0.56))
band.curve(to: p(0.50, 0.06), controlPoint1: p(0.92, 0.16), controlPoint2: p(0.74, 0.06))
band.curve(to: p(0.07, 0.36), controlPoint1: p(0.26, 0.06), controlPoint2: p(0.08, 0.16))
band.close()
NSColor(srgbRed: 0.06, green: 0.42, blue: 0.78, alpha: 1).setFill()
band.fill()

NSColor(srgbRed: 0.07, green: 0.43, blue: 0.78, alpha: 0.55).setFill()
path([p(0.04, 0.82), p(0.10, 0.72), p(0.05, 0.65)]).fill()
path([p(0.96, 0.82), p(0.90, 0.72), p(0.95, 0.65)]).fill()

// Cream face with the central blue notch.
let face = NSBezierPath()
face.move(to: p(0.50, 0.12))
face.curve(to: p(0.06, 0.41), controlPoint1: p(0.24, 0.12), controlPoint2: p(0.06, 0.20))
face.curve(to: p(0.39, 0.66), controlPoint1: p(0.06, 0.58), controlPoint2: p(0.20, 0.64))
face.line(to: p(0.50, 0.55))
face.line(to: p(0.61, 0.66))
face.curve(to: p(0.94, 0.41), controlPoint1: p(0.80, 0.64), controlPoint2: p(0.94, 0.58))
face.curve(to: p(0.50, 0.12), controlPoint1: p(0.94, 0.20), controlPoint2: p(0.76, 0.12))
face.close()
NSColor(srgbRed: 0.98, green: 0.82, blue: 0.54, alpha: 1).setFill()
face.fill()

let faceHighlight = NSBezierPath()
faceHighlight.move(to: p(0.08, 0.44))
faceHighlight.curve(to: p(0.38, 0.59), controlPoint1: p(0.10, 0.54), controlPoint2: p(0.23, 0.58))
faceHighlight.line(to: p(0.50, 0.46))
faceHighlight.line(to: p(0.62, 0.59))
faceHighlight.curve(to: p(0.92, 0.44), controlPoint1: p(0.77, 0.58), controlPoint2: p(0.90, 0.54))
faceHighlight.curve(to: p(0.50, 0.17), controlPoint1: p(0.88, 0.25), controlPoint2: p(0.74, 0.17))
faceHighlight.curve(to: p(0.08, 0.44), controlPoint1: p(0.26, 0.17), controlPoint2: p(0.12, 0.25))
faceHighlight.close()
NSColor(srgbRed: 1.0, green: 0.87, blue: 0.64, alpha: 0.75).setFill()
faceHighlight.fill()

// Eyes.
NSColor(srgbRed: 0.45, green: 0.36, blue: 0.35, alpha: 1).setStroke()
let eyeStroke: CGFloat = size * 0.04
for rect in [
    NSRect(x: size * 0.22, y: size * 0.46, width: size * 0.20, height: size * 0.10),
    NSRect(x: size * 0.58, y: size * 0.46, width: size * 0.20, height: size * 0.10),
] {
    let eye = NSBezierPath()
    eye.lineWidth = eyeStroke
    eye.lineCapStyle = .round
    eye.move(to: NSPoint(x: rect.minX, y: rect.midY))
    eye.curve(to: NSPoint(x: rect.maxX, y: rect.midY - size * 0.02),
              controlPoint1: NSPoint(x: rect.minX + rect.width * 0.40, y: rect.midY),
              controlPoint2: NSPoint(x: rect.minX + rect.width * 0.66, y: rect.midY - size * 0.01))
    eye.stroke()
}

// Mouth and teeth.
let mouth = NSBezierPath()
mouth.lineWidth = size * 0.045
mouth.lineCapStyle = .round
mouth.lineJoinStyle = .round
mouth.move(to: p(0.33, 0.31))
mouth.curve(to: p(0.67, 0.31), controlPoint1: p(0.42, 0.28), controlPoint2: p(0.58, 0.28))
NSColor(srgbRed: 0.45, green: 0.36, blue: 0.35, alpha: 1).setStroke()
mouth.stroke()

NSColor(srgbRed: 0.45, green: 0.36, blue: 0.35, alpha: 1).setFill()
path([p(0.30, 0.31), p(0.34, 0.42), p(0.39, 0.28)]).fill()
path([p(0.70, 0.31), p(0.66, 0.42), p(0.61, 0.28)]).fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to render icon\n".utf8))
    exit(1)
}
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/kabigon-icon-1024.png"
try png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
