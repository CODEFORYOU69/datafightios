//
//  RoundTests.swift
//  datafightTests
//
//  Created by younes ouasmi on 23/09/2024.
//

import XCTest
@testable import datafight

class RoundTests: XCTestCase {

    var sampleRound: Round!

    override func setUp() {
        super.setUp()
        sampleRound = Round(
            id: "testRoundId",
            fightId: "testFightId",
            creatorUserId: "testuser",
            roundNumber: 1,
            chronoDuration: 120,
            duration: 110,
            roundTime: 120,
            blueFighterId: "blueFighterId",
            redFighterId: "redFighterId",
            actions: [],
            videoReplays: [],
            isSynced: false,
            victoryDecision: nil,
            roundWinner: nil,
            blueHits: 5,
            redHits: 3,
            startTime: 0,
            endTime: 110
        )
    }

    override func tearDown() {
        sampleRound = nil
        super.tearDown()
    }

    func testRoundInitialization() {
        XCTAssertEqual(sampleRound.id, "testRoundId")
        XCTAssertEqual(sampleRound.fightId, "testFightId")
        XCTAssertEqual(sampleRound.roundNumber, 1)
        XCTAssertEqual(sampleRound.chronoDuration, 120)
        XCTAssertEqual(sampleRound.duration, 110)
        XCTAssertEqual(sampleRound.roundTime, 120)
        XCTAssertEqual(sampleRound.blueFighterId, "blueFighterId")
        XCTAssertEqual(sampleRound.redFighterId, "redFighterId")
        XCTAssertTrue(sampleRound.actions.isEmpty)
        XCTAssertTrue(sampleRound.videoReplays.isEmpty)
        XCTAssertFalse(sampleRound.isSynced)
        XCTAssertNil(sampleRound.victoryDecision)
        XCTAssertNil(sampleRound.roundWinner)
        XCTAssertEqual(sampleRound.blueHits, 5)
        XCTAssertEqual(sampleRound.redHits, 3)
        XCTAssertEqual(sampleRound.startTime, 0)
        XCTAssertEqual(sampleRound.endTime, 110)
    }

    func testBlueScore() {
        sampleRound.actions.append(Action(id: "1", fighterId: "blueFighterId", color: .blue, actionType: .kick, timeStamp: 10, videoTimestamp: 10, chronoTimestamp: 110))
        sampleRound.actions.append(Action(id: "2", fighterId: "blueFighterId", color: .blue, actionType: .punch, timeStamp: 20, videoTimestamp: 20, chronoTimestamp: 100))
        sampleRound.actions.append(Action(id: "3", fighterId: "blueFighterId", color: .blue, actionType: .gamJeon, timeStamp: 30, videoTimestamp: 30, chronoTimestamp: 90))
        // Ajoutez un gamjeon pour le combattant rouge
        sampleRound.actions.append(Action(id: "3", fighterId: "redFighterId", color: .red, actionType: .gamJeon, timeStamp: 30, videoTimestamp: 30, chronoTimestamp: 90))
        
        XCTAssertEqual(sampleRound.blueScore, 1) // 2 points pour le kick, 1 pour le punch, 1 pour le gamjeon rouge
    }

    func testRedScore() {
        sampleRound.actions.append(Action(id: "1", fighterId: "redFighterId", color: .red, actionType: .kick, timeStamp: 10, videoTimestamp: 10, chronoTimestamp: 110))
        sampleRound.actions.append(Action(id: "2", fighterId: "redFighterId", color: .red, actionType: .punch, timeStamp: 20, videoTimestamp: 20, chronoTimestamp: 100))
        sampleRound.actions.append(Action(id: "3", fighterId: "redFighterId", color: .red, actionType: .gamJeon, timeStamp: 30, videoTimestamp: 30, chronoTimestamp: 90))
        // Ajoutez un gamjeon pour le combattant bleu   
        sampleRound.actions.append(Action(id: "4", fighterId: "blueFighterId", color: .blue, actionType: .gamJeon, timeStamp: 40, videoTimestamp: 40, chronoTimestamp: 80))
        
        XCTAssertEqual(sampleRound.redScore, 1) // 2 points pour le kick, 1 pour le punch, 1 pour le gamjeon rouge
    }

    func testBlueGamJeon() {
        sampleRound.actions.append(Action(id: "1", fighterId: "blueFighterId", color: .blue, actionType: .gamJeon, timeStamp: 10, videoTimestamp: 10, chronoTimestamp: 110))
        sampleRound.actions.append(Action(id: "2", fighterId: "blueFighterId", color: .blue, actionType: .gamJeon, timeStamp: 20, videoTimestamp: 20, chronoTimestamp: 100))
        
        XCTAssertEqual(sampleRound.blueGamJeon, 2)
    }

    func testRedGamJeon() {
        // Similaire à testBlueGamJeon, mais pour le combattant rouge
        sampleRound.actions.append(Action(id: "1", fighterId: "redFighterId", color: .red, actionType: .gamJeon, timeStamp: 10, videoTimestamp: 10, chronoTimestamp: 110))
        sampleRound.actions.append(Action(id: "2", fighterId: "redFighterId", color: .red, actionType: .gamJeon, timeStamp: 20, videoTimestamp: 20, chronoTimestamp: 100))
        
        XCTAssertEqual(sampleRound.redGamJeon, 2)
    }

    func testIncrementHits() {
        sampleRound.incrementHits(for: .blue)
        XCTAssertEqual(sampleRound.blueHits, 6)
        
        sampleRound.incrementHits(for: .red)
        XCTAssertEqual(sampleRound.redHits, 4)
    }

    func testDetermineRoundWinner() {
        // Testez différents scénarios pour déterminer le gagnant du round
        
        // Scénario 1: Victoire par KO
        sampleRound.victoryDecision = .knockout
        sampleRound.actions.append(Action(id: "1", fighterId: "blueFighterId", color: .blue, actionType: .kick, timeStamp: 10, videoTimestamp: 10, chronoTimestamp: 110))
        sampleRound.determineRoundWinner()
        XCTAssertEqual(sampleRound.roundWinner, "blueFighterId")
        
        // Réinitialiser pour le prochain test
        sampleRound.roundWinner = nil
        sampleRound.actions.removeAll()
        
        // Scénario 2: Victoire par points
        sampleRound.victoryDecision = .finalScore
        sampleRound.actions.append(Action(id: "1", fighterId: "blueFighterId", color: .blue, actionType: .kick, timeStamp: 10, videoTimestamp: 10, chronoTimestamp: 110))
        sampleRound.actions.append(Action(id: "2", fighterId: "redFighterId", color: .red, actionType: .punch, timeStamp: 20, videoTimestamp: 20, chronoTimestamp: 100))
        sampleRound.determineRoundWinner()
        XCTAssertEqual(sampleRound.roundWinner, "blueFighterId")

        //Scénario 3: Victoire par décision de referee
        sampleRound.victoryDecision = .referee
        sampleRound.determineRoundWinner()
        XCTAssertEqual(sampleRound.roundWinner, "blueFighterId")

        //Scenario 4: Victoire par supériorité hits les plus hauts
        sampleRound.victoryDecision = .superiorityDecision
        sampleRound.determineRoundWinner()
        XCTAssertEqual(sampleRound.roundWinner, "blueFighterId")


        
    }

    // Ajoutez d'autres tests pour couvrir toutes les méthodes et propriétés du modèle Round
}
