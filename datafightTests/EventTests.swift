//
//  EventTests.swift
//  datafight
//
//  Created by younes ouasmi on 02/10/2024.
//


import XCTest
@testable import datafight

class EventTests: XCTestCase {

    var sampleEvent: Event!
    var sampleDate: Date!

    override func setUp() {
        super.setUp()
        
        // Créer une date de test
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        sampleDate = dateFormatter.date(from: "2024-10-10")

        // Initialiser un exemple d'événement
        sampleEvent = Event(
            id: "testEventId",
            creatorUserId: "testUserId",
            eventName: "Test Event",
            eventType: .nationalChampionship,
            location: "Paris",
            date: sampleDate,
            imageURL: "http://test.url/event.png",
            fightIds: ["fight1", "fight2"],
            country: "France"
        )
    }

    override func tearDown() {
        sampleEvent = nil
        sampleDate = nil
        super.tearDown()
    }

    func testEventInitialization() {
        XCTAssertEqual(sampleEvent.id, "testEventId")
        XCTAssertEqual(sampleEvent.creatorUserId, "testUserId")
        XCTAssertEqual(sampleEvent.eventName, "Test Event")
        XCTAssertEqual(sampleEvent.eventType, .nationalChampionship)
        XCTAssertEqual(sampleEvent.location, "Paris")
        XCTAssertEqual(sampleEvent.date, sampleDate)
        XCTAssertEqual(sampleEvent.imageURL, "http://test.url/event.png")
        XCTAssertEqual(sampleEvent.fightIds?.count, 2)
        XCTAssertEqual(sampleEvent.country, "France")
    }

    func testEventEncoding() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601 // Utilisation de la stratégie de date ISO8601 pour l'encodage
        
        let jsonData = try encoder.encode(sampleEvent)
        let jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        
        // Afficher le JSON encodé pour révision
        print(jsonString ?? "Failed to encode Event")
    }

    func testEventDecoding() throws {
        let json = """
        {
            "id": "testEventId",
            "creatorUserId": "testUserId",
            "eventName": "Test Event",
            "eventType": "National Championship",
            "location": "Paris",
            "date": "2024-10-10T00:00:00Z",
            "imageURL": "http://test.url/event.png",
            "fightIds": ["fight1", "fight2"],
            "country": "France"
        }
        """
        
        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Stratégie de décodage pour les dates
        
        let decodedEvent = try decoder.decode(Event.self, from: jsonData)
        
        XCTAssertEqual(decodedEvent.id, "testEventId")
        XCTAssertEqual(decodedEvent.creatorUserId, "testUserId")
        XCTAssertEqual(decodedEvent.eventName, "Test Event")
        XCTAssertEqual(decodedEvent.eventType, .nationalChampionship)
        XCTAssertEqual(decodedEvent.location, "Paris")
        XCTAssertEqual(decodedEvent.country, "France")
        XCTAssertEqual(decodedEvent.imageURL, "http://test.url/event.png")
        XCTAssertEqual(decodedEvent.fightIds?.count, 2)
    }

    func testEventWithoutImageAndFights() {
        let eventWithoutImageAndFights = Event(
            id: "testEventId",
            creatorUserId: "testUserId",
            eventName: "Test Event Without Image",
            eventType: .open,
            location: "London",
            date: sampleDate,
            country: "UK"
        )
        
        XCTAssertNil(eventWithoutImageAndFights.imageURL)
        XCTAssertNil(eventWithoutImageAndFights.fightIds)
        XCTAssertEqual(eventWithoutImageAndFights.eventName, "Test Event Without Image")
        XCTAssertEqual(eventWithoutImageAndFights.eventType, .open)
    }

    func testEventTypeRawValue() {
        XCTAssertEqual(EventType.nationalChampionship.rawValue, "National Championship")
        XCTAssertEqual(EventType.olympicGame.rawValue, "Olympic Game")
        XCTAssertEqual(EventType.g1.rawValue, "G1")
    }

    func testEventTypesCaseIterable() {
        let allEventTypes = EventType.allCases
        XCTAssertEqual(allEventTypes.count, 10) // Assurez-vous que tous les types d'événements sont couverts
    }
}
