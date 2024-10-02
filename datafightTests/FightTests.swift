//
//  FightTests.swift
//  datafight
//
//  Created by younes ouasmi on 02/10/2024.
//


import XCTest
@testable import datafight

class FightTests: XCTestCase {

    var sampleFight: Fight!
    var sampleFightResult: FightResult!

    override func setUp() {
        super.setUp()
        
        sampleFightResult = FightResult(
            winner: "blueFighterId",
            method: "KO",
            totalScore: (blue: 5, red: 3)
        )
        
        sampleFight = Fight(
            id: "testFightId",
            creatorUserId: "testUserId",
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighterId",
            redFighterId: "redFighterId",
            category: "Middleweight",
            weightCategory: "75-80kg",
            round: "Final",
            isOlympic: true,
            roundIds: ["round1", "round2"],
            fightResult: sampleFightResult,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false,
            videoId: "video123",
            videoURL: "http://test.url/video.mp4"
        )
    }

    override func tearDown() {
        sampleFight = nil
        sampleFightResult = nil
        super.tearDown()
    }

    func testFightInitialization() {
        XCTAssertEqual(sampleFight.id, "testFightId")
        XCTAssertEqual(sampleFight.creatorUserId, "testUserId")
        XCTAssertEqual(sampleFight.eventId, "testEventId")
        XCTAssertEqual(sampleFight.fightNumber, 1)
        XCTAssertEqual(sampleFight.blueFighterId, "blueFighterId")
        XCTAssertEqual(sampleFight.redFighterId, "redFighterId")
        XCTAssertEqual(sampleFight.category, "Middleweight")
        XCTAssertEqual(sampleFight.weightCategory, "75-80kg")
        XCTAssertEqual(sampleFight.round, "Final")
        XCTAssertTrue(sampleFight.isOlympic)
        XCTAssertEqual(sampleFight.roundIds?.count, 2)
        XCTAssertEqual(sampleFight.videoId, "video123")
        XCTAssertEqual(sampleFight.videoURL, "http://test.url/video.mp4")
    }

    func testFightResultInitialization() {
        XCTAssertEqual(sampleFight.fightResult?.winner, "blueFighterId")
        XCTAssertEqual(sampleFight.fightResult?.method, "KO")
        XCTAssertEqual(sampleFight.fightResult?.totalScore.blue, 5)
        XCTAssertEqual(sampleFight.fightResult?.totalScore.red, 3)
    }

    func testMarkVideoReplayAsUsed() {
        XCTAssertFalse(sampleFight.blueVideoReplayUsed)
        XCTAssertFalse(sampleFight.redVideoReplayUsed)
        
        sampleFight.markVideoReplayAsUsed(for: .blue)
        XCTAssertTrue(sampleFight.blueVideoReplayUsed)
        XCTAssertFalse(sampleFight.redVideoReplayUsed)

        sampleFight.markVideoReplayAsUsed(for: .red)
        XCTAssertTrue(sampleFight.redVideoReplayUsed)
    }

    func testUsedVideoReplay() {
        XCTAssertFalse(sampleFight.usedVideoReplay(for: .blue))
        XCTAssertFalse(sampleFight.usedVideoReplay(for: .red))
        
        sampleFight.markVideoReplayAsUsed(for: .blue)
        XCTAssertTrue(sampleFight.usedVideoReplay(for: .blue))
        XCTAssertFalse(sampleFight.usedVideoReplay(for: .red))
        
        sampleFight.markVideoReplayAsUsed(for: .red)
        XCTAssertTrue(sampleFight.usedVideoReplay(for: .red))
    }

    func testFightEncoding() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(sampleFight)
        
        let jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        
        // Print or log the JSON string for review
        print(jsonString ?? "Failed to encode Fight")
    }

}
