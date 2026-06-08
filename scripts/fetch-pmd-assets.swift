#!/usr/bin/env swift
import AppKit

// Fetches the Kanto starter evolution lines (dex 0001-0009) from PMDCollab's
// SpriteCollab, slices the south-facing row of each animation per AnimData.xml,
// pulls emotion portraits, and writes bundled resources + per-species meta.json
// under Sources/App/Resources/pmd/. Assets are CC BY-NC (see CREDITS.txt).

let raw = "https://raw.githubusercontent.com/PMDCollab/SpriteCollab/master"
let dexes = Array(1...9)
let wantedAnims = ["Idle", "Walk", "Sleep", "Hurt", "Eat", "Pose", "Charge", "Nod", "Hop"]
let wantedEmotions = [
    "Normal", "Happy", "Sad", "Angry", "Worried", "Determined",
    "Joyous", "Inspired", "Surprised", "Crying", "Pain", "Dizzy",
]

let outDir = URL(fileURLWithPath: "Sources/App/Resources/pmd")
let fm = FileManager.default

func slug(_ dex: Int) -> String { String(format: "%04d", dex) }

func fetch(_ path: String) -> Data? {
    guard let url = URL(string: "\(raw)/\(path)") else { return nil }
    return try? Data(contentsOf: url)
}

func cgImage(_ data: Data) -> CGImage? {
    NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
}

func savePNG(_ cg: CGImage, to url: URL) {
    let rep = NSBitmapImageRep(cgImage: cg)
    rep.size = NSSize(width: cg.width, height: cg.height)
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: url)
    }
}

/// One animation's geometry parsed from AnimData.xml.
struct AnimSpec { let name: String; let fw: Int; let fh: Int; let durations: [Int] }

func parseAnimData(_ data: Data) -> [String: AnimSpec] {
    guard let doc = try? XMLDocument(data: data) else { return [:] }
    var out: [String: AnimSpec] = [:]
    let nodes = (try? doc.nodes(forXPath: "//Anim")) ?? []
    for node in nodes {
        guard let el = node as? XMLElement else { continue }
        func child(_ n: String) -> String? { el.elements(forName: n).first?.stringValue }
        guard let name = child("Name"),
              let fw = child("FrameWidth").flatMap({ Int($0) }),
              let fh = child("FrameHeight").flatMap({ Int($0) }) else { continue }
        let durs = el.elements(forName: "Durations").first?
            .elements(forName: "Duration").compactMap { Int($0.stringValue ?? "") } ?? []
        out[name] = AnimSpec(name: name, fw: fw, fh: fh, durations: durs)
    }
    return out
}

/// Slices the south-facing (row 0) frames of a sheet.
func southRow(_ sheet: CGImage, fw: Int, fh: Int, count: Int) -> [CGImage] {
    guard fw > 0, fh > 0 else { return [] }
    let cols = sheet.width / fw
    let n = min(max(count, 1), cols)
    var frames: [CGImage] = []
    for c in 0..<n {
        let rect = CGRect(x: c * fw, y: 0, width: fw, height: fh)
        if let cropped = sheet.cropping(to: rect) { frames.append(cropped) }
    }
    return frames
}

func jsonString(_ obj: Any) -> String {
    let data = try! JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
    return String(data: data, encoding: .utf8)!
}

try? fm.createDirectory(at: outDir, withIntermediateDirectories: true)

for dex in dexes {
    let s = slug(dex)
    print("Processing \(s)…")
    let dir = outDir.appendingPathComponent(s)
    let animDir = dir.appendingPathComponent("anim")
    let portraitDir = dir.appendingPathComponent("portrait")
    try? fm.createDirectory(at: animDir, withIntermediateDirectories: true)
    try? fm.createDirectory(at: portraitDir, withIntermediateDirectories: true)

    guard let xml = fetch("sprite/\(s)/AnimData.xml") else {
        print("  ! no AnimData.xml"); continue
    }
    let specs = parseAnimData(xml)

    var animMeta: [String: Any] = [:]
    for anim in wantedAnims {
        guard let spec = specs[anim] else { continue }
        guard let sheetData = fetch("sprite/\(s)/\(anim)-Anim.png"),
              let sheet = cgImage(sheetData) else { continue }
        let count = spec.durations.isEmpty ? (sheet.width / spec.fw) : spec.durations.count
        let frames = southRow(sheet, fw: spec.fw, fh: spec.fh, count: count)
        guard !frames.isEmpty else { continue }
        let clipDir = animDir.appendingPathComponent(anim)
        try? fm.createDirectory(at: clipDir, withIntermediateDirectories: true)
        for (i, frame) in frames.enumerated() {
            savePNG(frame, to: clipDir.appendingPathComponent("\(i).png"))
        }
        let durs = spec.durations.isEmpty
            ? Array(repeating: 4, count: frames.count)
            : Array(spec.durations.prefix(frames.count))
        animMeta[anim] = ["frameCount": frames.count, "durations": durs]
    }

    var emotions: [String] = []
    for emotion in wantedEmotions {
        guard let data = fetch("portrait/\(s)/\(emotion).png"), let cg = cgImage(data) else { continue }
        savePNG(cg, to: portraitDir.appendingPathComponent("\(emotion).png"))
        emotions.append(emotion)
    }

    let meta: [String: Any] = ["dex": dex, "anims": animMeta, "portraits": emotions]
    try? jsonString(meta).write(to: dir.appendingPathComponent("meta.json"), atomically: true, encoding: .utf8)
    print("  ok: \(animMeta.count) anims, \(emotions.count) portraits")
}

let credits = """
Sprites and portraits in this folder are sourced from PMDCollab/SpriteCollab
(https://github.com/PMDCollab/SpriteCollab) and are licensed CC BY-NC 4.0.
They are used here non-commercially. See the repository for per-sprite authors.
"""
try? credits.write(to: outDir.appendingPathComponent("CREDITS.txt"), atomically: true, encoding: .utf8)
print("Done.")
