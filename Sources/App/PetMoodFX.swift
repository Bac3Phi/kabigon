import SwiftUI
import KabigonCore

enum WorkingVisualStyle: Equatable {
    case thinking
    case searching
    case testing
    case executing

    var animationNames: [String] {
        switch self {
        case .thinking: return ["Pose", "Idle"]
        case .searching: return ["Walk", "Charge", "Idle"]
        case .testing: return ["Nod", "Pose", "Idle"]
        case .executing: return ["Charge", "Attack", "Walk", "Idle"]
        }
    }

    var symbol: String {
        switch self {
        case .thinking: return "ellipsis.bubble.fill"
        case .searching: return "magnifyingglass"
        case .testing: return "checkmark.circle.fill"
        case .executing: return "bolt.fill"
        }
    }
}

/// Body motion for a given mood at time `t`, shared by all pet renderers.
struct PetMotion {
    var offsetY: CGFloat
    var rotation: Double
    var scaleX: CGFloat
    var scaleY: CGFloat

    static func resolve(_ mood: PetMood, _ t: Double, workingStyle: WorkingVisualStyle? = nil) -> PetMotion {
        switch mood {
        case .working:
            switch workingStyle ?? .executing {
            case .thinking:
                let breath = sin(t * 2.2)
                return PetMotion(offsetY: breath * 1.5, rotation: sin(t * 1.4) * 2.5,
                                 scaleX: 1 + 0.015 * breath, scaleY: 1 - 0.015 * breath)
            case .searching:
                return PetMotion(offsetY: -abs(sin(t * 4.2)) * 3, rotation: sin(t * 3.1) * 3,
                                 scaleX: 1, scaleY: 1)
            case .testing:
                let pulse = abs(sin(t * 3.4))
                return PetMotion(offsetY: -pulse * 2.5, rotation: 0,
                                 scaleX: 1 + pulse * 0.025, scaleY: 1 - pulse * 0.025)
            case .executing:
                let stride = abs(sin(t * 6.5))
                return PetMotion(offsetY: -stride * 4, rotation: sin(t * 13) * 1.8,
                                 scaleX: 1 + 0.02 * (1 - stride), scaleY: 1 - 0.02 * (1 - stride))
            }
        case .waiting:
            return PetMotion(offsetY: sin(t * 2.6) * 1.5, rotation: sin(t * 2.6) * 7, scaleX: 1, scaleY: 1)
        case .celebrate:
            let hop = abs(sin(t * 4))
            return PetMotion(offsetY: -hop * 7, rotation: sin(t * 8) * 5,
                             scaleX: 1 + 0.05 * (1 - hop), scaleY: 1 - 0.05 * (1 - hop))
        case .done:
            return PetMotion(offsetY: sin(t * 2) * 2.5, rotation: 0, scaleX: 1, scaleY: 1)
        case .idle:
            let b = sin(t * 1.7)
            return PetMotion(offsetY: b * 2, rotation: 0, scaleX: 1 + 0.02 * b, scaleY: 1 - 0.02 * b)
        }
    }
}

/// Mood overlays shared by all pet renderers: sparkles while celebrating and a
/// "?" bubble while waiting.
struct MoodAccessories: View {
    let mood: PetMood
    let t: Double
    let size: CGFloat
    var workingStyle: WorkingVisualStyle? = nil

    var body: some View {
        ZStack {
            if mood == .celebrate {
                ForEach(0..<4, id: \.self) { i in
                    let angle = Double(i) / 4 * .pi * 2
                    let twinkle = 0.35 + 0.65 * abs(sin(t * 4 + Double(i)))
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                        .opacity(twinkle)
                        .offset(x: cos(angle) * size * 0.34, y: -abs(sin(angle)) * size * 0.34 - size * 0.06)
                }
            }
            if mood == .working, let workingStyle {
                let pulse = 0.55 + 0.35 * abs(sin(t * 2.8))
                Image(systemName: workingStyle.symbol)
                    .font(.system(size: max(10, size * 0.11), weight: .bold))
                    .foregroundStyle(workingStyle == .testing ? .green : .white)
                    .padding(max(3, size * 0.025))
                    .background(Circle().fill(.black.opacity(0.35)))
                    .opacity(pulse)
                    .offset(x: size * 0.29, y: -size * 0.32 - sin(t * 2.4) * 2)
            }
        }
    }
}
