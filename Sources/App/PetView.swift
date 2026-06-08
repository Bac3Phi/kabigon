import SwiftUI
import KabigonCore

/// The pet sprite alone (PMD species, reacting to mood). Shows a paw
/// placeholder if no starter has been chosen yet.
struct PetView: View {
    var size: CGFloat = 120
    @ObservedObject private var pet = PetController.shared
    @ObservedObject private var progress = ProgressStore.shared
    @ObservedObject private var pmdStore = PMDPetStore.shared
    @State private var hearts: [PetHeart] = []
    @State private var pop = false
    @State private var evolution: PokemonEvolutionEvent?
    @State private var levelUp: PetLevelUpEvent?
    @State private var petReaction: PetReactionEvent?

    var body: some View {
        content
            .scaleEffect(pop ? 1.12 : 1, anchor: .bottom)
            .overlay(heartsOverlay)
            .overlay(reactionOverlay)
            .overlay(levelUpOverlay)
            .overlay(evolutionOverlay)
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .onTapGesture { handlePet() }
            .animation(.spring(response: 0.25, dampingFraction: 0.45), value: pop)
            .onChange(of: progress.justEvolvedTo) { evolved in
                guard let evolved else { return }
                triggerEvolution(evolved)
            }
            .onChange(of: progress.levelUpEvent) { event in
                guard let event else { return }
                triggerLevelUp(event)
            }
            .onChange(of: pet.petReaction) { reaction in
                guard let reaction else { return }
                triggerPetReaction(reaction)
            }
    }

    @ViewBuilder private var content: some View {
        if progress.hasChosenStarter,
           let species = pmdStore.loaded(dex: progress.displayDex) {
            PMDSpriteView(
                species: species,
                mood: pet.mood,
                size: size,
                preferredAnimNames: pet.petReaction?.animationNames
                    ?? (pet.mood == .working ? pet.workingVisualStyle.animationNames : nil),
                workingStyle: pet.mood == .working ? pet.workingVisualStyle : nil
            )
        } else {
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.secondary)
        }
    }

    private var heartsOverlay: some View {
        ZStack {
            ForEach(hearts) { heart in
                FloatingHeart(size: size, xJitter: heart.xJitter)
            }
        }
    }

    @ViewBuilder private var evolutionOverlay: some View {
        if let evolution {
            EvolutionBurst(size: size, speciesName: evolution.name)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    @ViewBuilder private var levelUpOverlay: some View {
        if let levelUp {
            LevelUpBurst(size: size, level: levelUp.level)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    @ViewBuilder private var reactionOverlay: some View {
        if let petReaction {
            PetReactionBurst(size: size, symbol: petReaction.symbol)
                .allowsHitTesting(false)
                .transition(.scale.combined(with: .opacity))
        }
    }

    /// Petting: always give visual feedback (hearts + a happy pop), and grant
    /// affection when off cooldown. Ignores taps before a starter is chosen.
    private func handlePet() {
        guard progress.hasChosenStarter else { return }
        progress.pet()
        pet.reactToPet()
        let heart = PetHeart()
        hearts.append(heart)
        pop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { pop = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            hearts.removeAll { $0.id == heart.id }
        }
    }

    private func triggerEvolution(_ species: PokemonEvolutionEvent) {
        evolution = species
        pop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { pop = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if evolution?.dex == species.dex {
                evolution = nil
                progress.justEvolvedTo = nil
            }
        }
    }

    private func triggerLevelUp(_ event: PetLevelUpEvent) {
        levelUp = event
        pop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { pop = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if levelUp == event {
                levelUp = nil
                progress.levelUpEvent = nil
            }
        }
    }

    private func triggerPetReaction(_ reaction: PetReactionEvent) {
        petReaction = reaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if petReaction == reaction { petReaction = nil }
        }
    }
}

/// One floating-heart particle spawned per pet tap.
private struct PetHeart: Identifiable {
    let id = UUID()
    let xJitter: CGFloat = .random(in: -0.18...0.18)
}

/// A heart that rises and fades above the pet when it's petted.
private struct FloatingHeart: View {
    let size: CGFloat
    let xJitter: CGFloat
    @State private var rise = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size * 0.16))
            .foregroundStyle(.pink)
            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            .offset(x: xJitter * size, y: rise ? -size * 0.55 : -size * 0.08)
            .opacity(rise ? 0 : 1)
            .scaleEffect(rise ? 1.2 : 0.5)
            .onAppear { withAnimation(.easeOut(duration: 0.9)) { rise = true } }
    }
}

private struct LevelUpBurst: View {
    let size: CGFloat
    let level: Int
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(index.isMultiple(of: 2) ? Color.yellow : Color.cyan)
                    .frame(width: max(2, size * 0.025), height: size * 0.2)
                    .offset(y: animate ? -size * 0.48 : -size * 0.1)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .opacity(animate ? 0 : 0.9)
                    .animation(.easeOut(duration: 0.9).delay(Double(index % 2) * 0.05), value: animate)
            }

            Text("LEVEL \(level)")
                .font(.system(size: max(11, size * 0.115), weight: .black))
                .foregroundStyle(.yellow)
                .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
                .offset(y: animate ? -size * 0.42 : -size * 0.12)
                .opacity(animate ? 0 : 1)
                .scaleEffect(animate ? 1.12 : 0.7)
        }
        .frame(width: size, height: size)
        .onAppear { withAnimation(.easeOut(duration: 1.35)) { animate = true } }
    }
}

private struct PetReactionBurst: View {
    let size: CGFloat
    let symbol: String
    @State private var appear = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: max(14, size * 0.18), weight: .bold))
            .foregroundStyle(symbol.contains("heart") ? .pink : .yellow)
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            .offset(x: size * 0.28, y: appear ? -size * 0.38 : -size * 0.12)
            .scaleEffect(appear ? 1 : 0.25)
            .opacity(appear ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 1.35)) { appear = true } }
    }
}

/// Short evolution celebration: a white flash, expanding energy rings, and
/// sparkle particles around the newly evolved sprite.
private struct EvolutionBurst: View {
    let size: CGFloat
    let speciesName: String
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: size * 1.1, height: size * 1.1)
                .scaleEffect(animate ? 1.35 : 0.15)
                .opacity(animate ? 0 : 0.88)

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(.white.opacity(0.85), lineWidth: max(2, size * 0.025))
                    .frame(width: size * 0.45, height: size * 0.45)
                    .scaleEffect(animate ? 1.4 + CGFloat(index) * 0.22 : 0.35)
                    .opacity(animate ? 0 : 0.95)
                    .animation(.easeOut(duration: 1.05).delay(Double(index) * 0.15), value: animate)
            }

            ForEach(0..<10, id: \.self) { index in
                EvolutionSpark(size: size, index: index, animate: animate)
            }

            VStack(spacing: 3) {
                Spacer()
                Text("\(speciesName)!")
                    .font(.system(size: max(11, size * 0.12), weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? -size * 0.08 : size * 0.05)
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { animate = true }
        }
    }
}

private struct EvolutionSpark: View {
    let size: CGFloat
    let index: Int
    let animate: Bool

    private var angle: Double { Double(index) / 10.0 * .pi * 2 }
    private var radius: CGFloat { size * (0.28 + CGFloat(index % 3) * 0.06) }

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: max(9, size * 0.09), weight: .bold))
            .foregroundStyle(.yellow)
            .shadow(color: .white.opacity(0.75), radius: 4)
            .offset(
                x: animate ? cos(angle) * radius : 0,
                y: animate ? sin(angle) * radius - size * 0.08 : 0
            )
            .scaleEffect(animate ? 1.1 : 0.2)
            .opacity(animate ? 0 : 1)
            .animation(.easeOut(duration: 1.25).delay(Double(index % 4) * 0.08), value: animate)
    }
}

/// The full floating window content: a chat bubble above the pet.
struct FloatingPetView: View {
    @ObservedObject private var pet = PetController.shared
    @ObservedObject private var progress = ProgressStore.shared
    @ObservedObject private var pmdStore = PMDPetStore.shared

    var body: some View {
        VStack(spacing: 2) {
            if pet.showChat && !pet.chatLine.isEmpty && progress.hasChosenStarter {
                ChatBubble(
                    text: pet.chatLine,
                    portrait: portrait,
                    maxWidth: min(270, pet.windowSize.width - 20)
                )
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            PetView(size: pet.petPoint)
        }
        .frame(width: pet.windowSize.width, height: pet.windowSize.height, alignment: .bottom)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: pet.chatLine)
        .animation(.easeInOut, value: pet.showChat)
    }

    /// The current species' portrait for the active emotion (falls back to the
    /// neutral face), shown inside the chat bubble.
    private var portrait: NSImage? {
        guard let species = pmdStore.loaded(dex: progress.displayDex) else { return nil }
        return species.portrait(pet.emotion.portraitName) ?? species.portrait("Normal")
    }
}

/// A speech bubble with a little downward tail.
private struct ChatBubble: View {
    let text: String
    var portrait: NSImage? = nil
    let maxWidth: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 6) {
                if let portrait {
                    Image(nsImage: portrait)
                        .resizable().interpolation(.none).scaledToFit()
                        .frame(width: 22, height: 22)
                }
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.black.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: maxWidth, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
            Triangle()
                .fill(.white)
                .frame(width: 12, height: 7)
        }
        .frame(maxWidth: maxWidth + 24)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
