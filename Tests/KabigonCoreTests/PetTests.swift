import XCTest
@testable import KabigonCore

final class MoodResolverTests: XCTestCase {
    private func session(_ state: AgentState, id: String) -> AgentSession {
        AgentSession(id: id, agentKind: .claude, state: state, source: .hook,
                     updatedAt: Date(timeIntervalSince1970: 0))
    }

    func testEmptyIsIdle() {
        XCTAssertEqual(MoodResolver.aggregate([]), .idle)
    }

    func testWorkingWins() {
        let sessions = [session(.working, id: "a"), session(.waiting, id: "b"), session(.done, id: "c")]
        XCTAssertEqual(MoodResolver.aggregate(sessions), .working, "running work is prioritised")
    }

    func testWaitingBeatsDone() {
        XCTAssertEqual(MoodResolver.aggregate([session(.done, id: "a"), session(.waiting, id: "b")]), .waiting)
    }

    func testRegisteredIsNotWorking() {
        // An agent that is merely open (registered) but not doing anything keeps
        // the pet idle, not "working".
        XCTAssertEqual(MoodResolver.aggregate([session(.registered, id: "a")]), .idle)
        XCTAssertEqual(MoodResolver.aggregate([session(.registered, id: "a"), session(.working, id: "b")]), .working)
    }

    func testDoneOnly() {
        XCTAssertEqual(MoodResolver.aggregate([session(.done, id: "a"), session(.idle, id: "b")]), .done)
    }
}

final class EmotionResolverTests: XCTestCase {
    func testMoodBaselines() {
        XCTAssertEqual(EmotionResolver.resolve(mood: .idle, message: nil), .normal)
        XCTAssertEqual(EmotionResolver.resolve(mood: .working, message: nil), .determined)
        XCTAssertEqual(EmotionResolver.resolve(mood: .waiting, message: nil), .worried)
        XCTAssertEqual(EmotionResolver.resolve(mood: .done, message: nil), .happy)
        XCTAssertEqual(EmotionResolver.resolve(mood: .celebrate, message: nil), .joyous)
    }

    func testErrorOverridesMood() {
        XCTAssertEqual(EmotionResolver.resolve(mood: .working, message: "Build failed"), .pain)
        XCTAssertEqual(EmotionResolver.resolve(mood: .waiting, message: "fatal error: not found"), .crying)
    }

    func testContextRefinesWorking() {
        XCTAssertEqual(EmotionResolver.resolve(mood: .working, message: "Searching the codebase"), .inspired)
        XCTAssertEqual(EmotionResolver.resolve(mood: .working, message: "Running tests"), .surprised)
    }

    func testWaitingQuestionIsSurprised() {
        XCTAssertEqual(EmotionResolver.resolve(mood: .waiting, message: "Approve this edit?"), .surprised)
    }
}

final class PokedexDataTests: XCTestCase {
    func testUpsertAndFlags() {
        var data = PokedexData.empty
        data.upsert(dex: 25, level: 5, isNew: true)
        XCTAssertTrue(data.isCaught(25))
        XCTAssertEqual(data.newCount, 1)
        XCTAssertFalse(data.entry(dex: 25)?.isShiny ?? true)

        // Re-catching keeps the higher level and does not duplicate the entry.
        data.upsert(dex: 25, level: 3, isNew: false)
        XCTAssertEqual(data.caughtCount, 1)
        XCTAssertEqual(data.entry(dex: 25)?.level, 5)

        data.upsert(dex: 25, level: 4, isShiny: true, isNew: false)
        XCTAssertTrue(data.entry(dex: 25)?.isShiny ?? false)

        data.clearAllNew()
        XCTAssertEqual(data.newCount, 0)
    }

    func testGen1Names() {
        XCTAssertEqual(Gen1Pokedex.count, 151)
        XCTAssertEqual(Gen1Pokedex.name(for: 1), "Bulbasaur")
        XCTAssertEqual(Gen1Pokedex.name(for: 151), "Mew")
        XCTAssertNil(Gen1Pokedex.name(for: 152))
    }

    func testSupportedPokedexIncludesGen2() {
        XCTAssertEqual(PokemonPokedex.count, 251)
        XCTAssertEqual(PokemonPokedex.name(for: 1), "Bulbasaur")
        XCTAssertEqual(PokemonPokedex.name(for: 152), "Chikorita")
        XCTAssertEqual(PokemonPokedex.name(for: 251), "Celebi")
        XCTAssertNil(PokemonPokedex.name(for: 252))
    }

    func testStarterChoicesIncludeJohtoBasics() {
        XCTAssertEqual(PMDCatalog.starterDexes, [1, 4, 7, 152, 155, 158])
        XCTAssertEqual(PMDCatalog.line(root: 152).map(\.dex), [152, 153, 154])
        XCTAssertEqual(PMDCatalog.line(root: 155).map(\.dex), [155, 156, 157])
        XCTAssertEqual(PMDCatalog.line(root: 158).map(\.dex), [158, 159, 160])
    }

    func testEveryGen1PokemonHasASpeciesDescription() {
        XCTAssertEqual(Gen1Pokedex.descriptions.count, Gen1Pokedex.count)
        for dex in Gen1Pokedex.dexRange {
            XCTAssertFalse(Gen1Pokedex.description(for: dex)?.isEmpty ?? true, "Missing description for #\(dex)")
        }
        XCTAssertNil(Gen1Pokedex.description(for: 0))
        XCTAssertNil(Gen1Pokedex.description(for: 152))
    }

    func testEverySupportedPokemonHasASpeciesDescription() {
        XCTAssertEqual(Gen2Pokedex.descriptions.count, Gen2Pokedex.count)
        for dex in PokemonPokedex.dexRange {
            XCTAssertFalse(PokemonPokedex.description(for: dex)?.isEmpty ?? true, "Missing description for #\(dex)")
        }
        XCTAssertNil(PokemonPokedex.description(for: 0))
        XCTAssertNil(PokemonPokedex.description(for: 252))
    }

    func testPersistenceRoundTrip() throws {
        let dir = NSTemporaryDirectory() + "kabigon-tests-" + UUID().uuidString
        defer { try? FileManager.default.removeItem(atPath: dir) }

        var data = PokedexData.empty
        data.upsert(dex: 6, level: 36, isNew: true)
        data.save(directory: dir)

        let loaded = PokedexData.load(directory: dir)
        XCTAssertEqual(loaded.entry(dex: 6)?.level, 36)
        XCTAssertTrue(loaded.entry(dex: 6)?.isNew ?? false)
    }

    func testLegacyPokedexEntryDefaultsToNotShiny() throws {
        let json = #"{"entries":[{"dex":25,"level":12,"isNew":false,"caughtAt":12345}]}"#
        let loaded = try EventCoding.decoder.decode(PokedexData.self, from: Data(json.utf8))
        XCTAssertEqual(loaded.entry(dex: 25)?.level, 12)
        XCTAssertFalse(loaded.entry(dex: 25)?.isShiny ?? true)
    }
}

final class Gen1EvolutionCatalogTests: XCTestCase {
    func testCanonicalLevelEvolution() {
        XCTAssertEqual(
            Gen1EvolutionCatalog.evolutions(from: 10),
            [EvolutionRule(fromDex: 10, toDex: 11, level: 7, method: .level)]
        )
    }

    func testStoneAndTradeUseGameThresholds() {
        XCTAssertEqual(
            Gen1EvolutionCatalog.evolutions(from: 25),
            [EvolutionRule(fromDex: 25, toDex: 26, level: 30, method: .stone)]
        )
        XCTAssertEqual(
            Gen1EvolutionCatalog.evolutions(from: 93),
            [EvolutionRule(fromDex: 93, toDex: 94, level: 36, method: .trade)]
        )
    }

    func testEeveeUnlocksAllGen1Branches() {
        XCTAssertEqual(Gen1EvolutionCatalog.evolutions(from: 133).map(\.toDex), [134, 135, 136])
    }

    func testRulesStayInsideGen1Pokedex() {
        XCTAssertTrue(Gen1EvolutionCatalog.rules.allSatisfy {
            Gen1Pokedex.dexRange.contains($0.fromDex)
                && Gen1Pokedex.dexRange.contains($0.toDex)
                && $0.level > 1
        })
    }

    func testSupportedEvolutionCatalogIncludesJohtoAndCrossGenRules() {
        XCTAssertEqual(
            PokemonEvolutionCatalog.evolutions(from: 152),
            [EvolutionRule(fromDex: 152, toDex: 153, level: 16, method: .level)]
        )
        XCTAssertEqual(PokemonEvolutionCatalog.evolutions(from: 44).map(\.toDex), [45, 182])
        XCTAssertEqual(PokemonEvolutionCatalog.evolutions(from: 133).map(\.toDex), [134, 135, 136, 196, 197])
        XCTAssertTrue(PokemonEvolutionCatalog.rules.allSatisfy {
            PokemonPokedex.dexRange.contains($0.fromDex)
                && PokemonPokedex.dexRange.contains($0.toDex)
                && $0.level > 1
        })
    }

    func testReceivablePokemonAreOnlyBasicForms() {
        XCTAssertTrue(PokemonEvolutionCatalog.isReceivable(1))
        XCTAssertTrue(PokemonEvolutionCatalog.isReceivable(133), "Eevee should remain receivable despite branching evolutions")
        XCTAssertTrue(PokemonEvolutionCatalog.isReceivable(152))
        XCTAssertFalse(PokemonEvolutionCatalog.isReceivable(2))
        XCTAssertFalse(PokemonEvolutionCatalog.isReceivable(25), "Pichu is now the basic form for Pikachu's family")
        XCTAssertFalse(PokemonEvolutionCatalog.isReceivable(182))
    }
}
