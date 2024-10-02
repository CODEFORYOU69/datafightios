//
//  FighterTests.swift
//  datafight
//
//  Created by younes ouasmi on 02/10/2024.
//


import XCTest
@testable import datafight

class FighterTests: XCTestCase {

    var sampleFighter: Fighter!
    var sampleDate: Date!

    override func setUp() {
        super.setUp()

        // Créer une date de test
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        sampleDate = dateFormatter.date(from: "1990-01-01")

        // Initialiser un exemple de Fighter
        sampleFighter = Fighter(
            id: "testFighterId",
            creatorUserId: "testUserId",
            firstName: "John",
            lastName: "Doe",
            gender: "Male",
            birthdate: sampleDate,
            country: "USA",
            profileImageURL: "http://test.url/fighter.png",
            fightIds: ["fight1", "fight2"]
        )
    }

    override func tearDown() {
        sampleFighter = nil
        sampleDate = nil
        super.tearDown()
    }

    func testFighterInitialization() {
        XCTAssertEqual(sampleFighter.id, "testFighterId")
        XCTAssertEqual(sampleFighter.creatorUserId, "testUserId")
        XCTAssertEqual(sampleFighter.firstName, "John")
        XCTAssertEqual(sampleFighter.lastName, "Doe")
        XCTAssertEqual(sampleFighter.gender, "Male")
        XCTAssertEqual(sampleFighter.birthdate, sampleDate)
        XCTAssertEqual(sampleFighter.country, "USA")
        XCTAssertEqual(sampleFighter.profileImageURL, "http://test.url/fighter.png")
        XCTAssertEqual(sampleFighter.fightIds?.count, 2)
    }

    func testFighterEncoding() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601 // Utilisation de la stratégie de date ISO8601 pour l'encodage
        
        let jsonData = try encoder.encode(sampleFighter)
        let jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        
        // Afficher le JSON encodé pour révision
        print(jsonString ?? "Failed to encode Fighter")
    }

   

    func testFighterWithoutOptionalFields() {
        let fighterWithoutOptionalFields = Fighter(
            id: "testFighterId",
            creatorUserId: "testUserId",
            firstName: "John",
            lastName: "Doe",
            gender: "Male",
            birthdate: nil,
            country: "USA"
        )
        
        XCTAssertNil(fighterWithoutOptionalFields.birthdate)
        XCTAssertNil(fighterWithoutOptionalFields.profileImageURL)
        XCTAssertNil(fighterWithoutOptionalFields.fightIds)
        XCTAssertEqual(fighterWithoutOptionalFields.firstName, "John")
        XCTAssertEqual(fighterWithoutOptionalFields.gender, "Male")
        XCTAssertEqual(fighterWithoutOptionalFields.country, "USA")
    }

    func testFighterWithEmptyFightIds() {
        let fighterWithNoFights = Fighter(
            id: "testFighterId",
            creatorUserId: "testUserId",
            firstName: "John",
            lastName: "Doe",
            gender: "Male",
            birthdate: sampleDate,
            country: "USA",
            fightIds: []
        )
        
        XCTAssertEqual(fighterWithNoFights.fightIds?.count, 0)
        XCTAssertEqual(fighterWithNoFights.firstName, "John")
        XCTAssertEqual(fighterWithNoFights.lastName, "Doe")
    }
}
