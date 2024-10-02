//
//  VideoTests.swift
//  datafight
//
//  Created by younes ouasmi on 02/10/2024.
//


import XCTest
@testable import datafight

class VideoTests: XCTestCase {

    var sampleVideo: Video!
    var sampleRoundTimestamps: [RoundTimestamp]!

    override func setUp() {
        super.setUp()

        // Initialiser des timestamps de round pour les tests
        sampleRoundTimestamps = [
            RoundTimestamp(roundNumber: 1, start: 0.0, end: 120.0),
            RoundTimestamp(roundNumber: 2, start: 121.0, end: 240.0)
        ]

        // Initialiser un exemple de vidéo
        sampleVideo = Video(
            id: "videoId",
            fightId: "fightId",
            url: "http://test.url/video.mp4",
            duration: 300.0,
            roundTimestamps: sampleRoundTimestamps
        )
    }

    override func tearDown() {
        sampleVideo = nil
        sampleRoundTimestamps = nil
        super.tearDown()
    }

    func testVideoInitialization() {
        XCTAssertEqual(sampleVideo.id, "videoId")
        XCTAssertEqual(sampleVideo.fightId, "fightId")
        XCTAssertEqual(sampleVideo.url, "http://test.url/video.mp4")
        XCTAssertEqual(sampleVideo.duration, 300.0)
        XCTAssertEqual(sampleVideo.roundTimestamps.count, 2)
    }

    func testAddNewRoundTimestamp() {
        // Ajouter un nouveau timestamp pour un round inexistant
        sampleVideo.updateOrAddRoundTimestamp(roundNumber: 3, start: 241.0, end: 300.0)
        XCTAssertEqual(sampleVideo.roundTimestamps.count, 3)

        let addedRound = sampleVideo.roundTimestamps.first(where: { $0.roundNumber == 3 })
        XCTAssertNotNil(addedRound)
        XCTAssertEqual(addedRound?.start, 241.0)
        XCTAssertEqual(addedRound?.end, 300.0)
    }

    func testUpdateExistingRoundTimestamp() {
        // Mettre à jour un timestamp existant
        sampleVideo.updateOrAddRoundTimestamp(roundNumber: 2, start: 125.0, end: 245.0)

        let updatedRound = sampleVideo.roundTimestamps.first(where: { $0.roundNumber == 2 })
        XCTAssertNotNil(updatedRound)
        XCTAssertEqual(updatedRound?.start, 125.0)
        XCTAssertEqual(updatedRound?.end, 245.0)
    }

    func testVideoDictionaryConversion() {
        let videoDict = sampleVideo.dictionary

        XCTAssertEqual(videoDict["id"] as? String, "videoId")
        XCTAssertEqual(videoDict["fightId"] as? String, "fightId")
        XCTAssertEqual(videoDict["url"] as? String, "http://test.url/video.mp4")
        XCTAssertEqual(videoDict["duration"] as? Double, 300.0)
        
        let roundTimestampsDict = videoDict["roundTimestamps"] as? [[String: Any]]
        XCTAssertEqual(roundTimestampsDict?.count, 2)
        
        let firstRoundDict = roundTimestampsDict?.first
        XCTAssertEqual(firstRoundDict?["roundNumber"] as? Int, 1)
        XCTAssertEqual(firstRoundDict?["start"] as? TimeInterval, 0.0)
        XCTAssertEqual(firstRoundDict?["end"] as? TimeInterval, 120.0)
    }

   
    func testRoundTimestampInitialization() {
        let roundTimestamp = RoundTimestamp(roundNumber: 1, start: 10.0, end: 100.0)
        XCTAssertEqual(roundTimestamp.roundNumber, 1)
        XCTAssertEqual(roundTimestamp.start, 10.0)
        XCTAssertEqual(roundTimestamp.end, 100.0)
    }

    func testRoundTimestampDictionaryConversion() {
        let roundTimestamp = RoundTimestamp(roundNumber: 1, start: 10.0, end: 100.0)
        let dict = roundTimestamp.dictionary

        XCTAssertEqual(dict["roundNumber"] as? Int, 1)
        XCTAssertEqual(dict["start"] as? TimeInterval, 10.0)
        XCTAssertEqual(dict["end"] as? TimeInterval, 100.0)
    }

    func testRoundTimestampInitializationFromDictionary() {
        let dict: [String: Any] = [
            "roundNumber": 1,
            "start": 10.0,
            "end": 100.0
        ]

        let roundTimestamp = RoundTimestamp(dictionary: dict)

        XCTAssertNotNil(roundTimestamp)
        XCTAssertEqual(roundTimestamp?.roundNumber, 1)
        XCTAssertEqual(roundTimestamp?.start, 10.0)
        XCTAssertEqual(roundTimestamp?.end, 100.0)
    }
}
