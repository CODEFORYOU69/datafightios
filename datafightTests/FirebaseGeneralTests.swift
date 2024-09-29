//
//  FirebaseGeneralTests.swift
//  datafightTests
//
//  Created by younes ouasmi on 25/09/2024.
//
import XCTest
@testable import datafight
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore


class FirebaseGeneralTests: XCTestCase {
    
    var firebaseService: FirebaseService!
    
    override func setUp() {
        super.setUp()
        firebaseService = FirebaseService.shared

        // Clear the emulator data before each test
        let clearExpectation = expectation(description: "Clear emulators")
        clearEmulators {
            clearExpectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)

        // Authenticate the test user
        let email = "test@example.com"
        let password = "password123"

        let createUserExpectation = expectation(description: "Create or sign in test user")
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            if let error = error as NSError?, error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                // User exists, sign in
                Auth.auth().signIn(withEmail: email, password: password) { _, error in
                    XCTAssertNil(error, "Failed to sign in test user")
                    createUserExpectation.fulfill()
                }
            } else {
                XCTAssertNil(error, "Failed to create test user")
                createUserExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    
    override func tearDown() {
        super.tearDown()
        firebaseService = nil

        // Optionally clear emulators after each test
        let clearExpectation = self.expectation(description: "Clear emulators")
        clearEmulators {
            clearExpectation.fulfill()
        }
        wait(for: [clearExpectation], timeout: 20.0)
    }
    
    override func tearDownWithError() throws {
      self.firebaseService = nil
    }
    
    func createAndSignInUser(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                completion(.failure(error))
            } else if let userId = authResult?.user.uid {
                completion(.success(userId))
            } else {
                completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])))
            }
        }
    }

    
    func testCreateUser() {
        let expectation = self.expectation(description: "Create user")

        // Generate a unique email for the test user
        let uniqueEmail = "test+\(UUID().uuidString)@example.com"
        let password = "password123"

        // Sign out first to ensure a clean state
        try? Auth.auth().signOut()

        // Create a test user with unique email
        Auth.auth().createUser(withEmail: uniqueEmail, password: password) { (authResult, error) in
            if let error = error {
                XCTFail("Failed to create test user: \(error.localizedDescription)")
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(authResult?.user, "Auth result should contain a user")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testUpdateUserProfile() {
        let expectation = self.expectation(description: "Update user profile")

        // Generate a unique email for the test user
        let uniqueEmail = "test+\(UUID().uuidString)@example.com"
        let password = "password123"

        // Sign out first to ensure a clean state
        try? Auth.auth().signOut()

        // Create and sign in with a unique test user
        Auth.auth().createUser(withEmail: uniqueEmail, password: password) { (authResult, error) in
            if let error = error {
                XCTFail("Failed to create test user: \(error.localizedDescription)")
                expectation.fulfill()
                return
            }

            guard let userId = authResult?.user.uid else {
                XCTFail("User ID should not be nil")
                expectation.fulfill()
                return
            }

            let updatedUser = User(id: userId, firstName: "John", lastName: "Doe", dateOfBirth: Date(), role: "coach", teamName: "Team USA", country: "USA", profileImageURL: nil)

            // Test the `updateUserProfile` method
            self.firebaseService.updateUserProfile(updatedUser) { result in
                switch result {
                case .success:
                    // Now retrieve the profile to check if it was updated
                    self.firebaseService.getUserProfile { result in
                        switch result {
                        case .success(let user):
                            XCTAssertEqual(user.firstName, "John", "First name should be updated to John")
                            XCTAssertEqual(user.role, "coach", "Role should be updated to coach")
                            expectation.fulfill()
                        case .failure(let error):
                            XCTFail("Failed to retrieve updated user profile: \(error.localizedDescription)")
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    XCTFail("Failed to update user profile: \(error.localizedDescription)")
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 20, handler: nil)
    }

    // MARK: - Test getUserProfile function

    func testGetUserProfile() {
        let expectation = self.expectation(description: "Get user profile")

        // Generate a unique email for the test user
        let uniqueEmail = "test+\(UUID().uuidString)@example.com"
        let password = "password123"

        // Sign out to ensure clean state
        try? Auth.auth().signOut()

        // Create and sign in with a unique test user
        Auth.auth().createUser(withEmail: uniqueEmail, password: password) { (authResult, error) in
            if let error = error {
                XCTFail("Failed to create test user: \(error.localizedDescription)")
                expectation.fulfill()
                return
            }

            guard let userId = authResult?.user.uid else {
                XCTFail("User ID should not be nil")
                expectation.fulfill()
                return
            }

            // Optionally, update the user profile to have a known first name
            let updatedUser = User(id: userId, firstName: "John", lastName: "Doe", dateOfBirth: Date(), role: "coach", teamName: "Team USA", country: "USA", profileImageURL: nil)

            self.firebaseService.updateUserProfile(updatedUser) { result in
                switch result {
                case .success:
                    // Now test the `getUserProfile` method
                    self.firebaseService.getUserProfile { result in
                        switch result {
                        case .success(let user):
                            XCTAssertNotNil(user, "User profile should not be nil")
                            XCTAssertEqual(user.firstName, "John")
                            expectation.fulfill()
                        case .failure(let error):
                            XCTFail("Failed to get user profile: \(error.localizedDescription)")
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    XCTFail("Failed to update user profile: \(error.localizedDescription)")
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 20, handler: nil)
    }

    
    // MARK: - Test uploadProfileImage function

    func testUploadProfileImage() {
        let expectation = self.expectation(description: "Upload profile image")
        
        // Load an image from your app's assets (replace "user_avatar" with your actual asset name)
        guard let image = UIImage(named: "user_avatar") else {
            XCTFail("Image not found in assets")
            return
        }
        
        // Test the `uploadProfileImage` method
        self.firebaseService.uploadProfileImage(image) { result in
            switch result {
            case .success(let url):
                XCTAssertNotNil(url, "URL for uploaded image should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to upload profile image: \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 20, handler: nil)
    }
    // MARK: - Test saveFighter function
    
    func test3_testSaveFighter() {
        let expectation = self.expectation(description: "Save fighter")
        
        let fighter = Fighter(
            creatorUserId: "testUser",
            firstName: "John",
            lastName: "Doe",
            gender: "Male",
            birthdate: Date(),
            country: "USA",
            profileImageURL: nil,
            fightIds: nil
        )
        
        firebaseService.saveFighter(fighter) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to save fighter: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    // MARK: - Test saveEvent function

    func test1_testSaveEvent() {
        let expectation = self.expectation(description: "Save event")

        let event = Event(
            creatorUserId: "testUser",
            eventName: "Test Event",
            eventType: .open,
            location: "New York",
            date: Date(),
            country: "USA"
        )

        firebaseService.saveEvent(event) { result in
            switch result {
            case .success(let eventId):
                XCTAssertNotNil(eventId, "Event ID should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to save event: \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
    // MARK: - Test saveFight function
    func test2_testSaveFight() {
        let expectation = self.expectation(description: "Save fight")
        
        let fight = Fight(
            creatorUserId: "testUser",
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            roundIds: nil,
            fightResult: nil,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false,
            videoId: nil,
            videoURL: nil
        )
        
        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                XCTAssertNotNil(fightId, "Fight ID should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    func testStorageConnection() {
        let expectation = self.expectation(description: "Storage connection")
        
        let data = "Test data".data(using: .utf8)!
        let ref = firebaseService.storage.child("test/testfile.txt")
        
        ref.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                XCTFail("Failed to upload to Storage: \(error.localizedDescription)")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testNetworkConnectivity() {
        XCTAssertTrue(firebaseService.isConnected, "Should be connected by default")
        
        // Note: Testing actual network changes is challenging in unit tests
        // You might want to add some mock network changes if needed
    }
    
    // MARK: - Test getFight function
    func test4_testGetFight() {
        let saveFightExpectation = self.expectation(description: "Save fight")
        let getFightExpectation = self.expectation(description: "Get fight")

        let fight = Fight(
            creatorUserId: "testUser",
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            roundIds: nil,
            fightResult: nil,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false,
            videoId: nil,
            videoURL: nil
        )
        
        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                saveFightExpectation.fulfill()
                self.firebaseService.getFight(id: fightId) { result in
                    switch result {
                    case .success(let retrievedFight):
                        XCTAssertEqual(retrievedFight.fightNumber, 1, "Fight number should be 1")
                        getFightExpectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to get fight: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    // MARK: - Test updateFight function
    func test5_testUpdateFight() {
        let saveFightExpectation = self.expectation(description: "Save fight")
        let updateFightExpectation = self.expectation(description: "Update fight")

        // Ensure the user is authenticated first
        if let uid = Auth.auth().currentUser?.uid {
            let fight = Fight(
                creatorUserId: uid,  // Use authenticated user's UID here
                eventId: "testEventId",
                fightNumber: 1,
                blueFighterId: "blueFighter",
                redFighterId: "redFighter",
                category: "Adult",
                weightCategory: "Lightweight",
                round: "Final",
                isOlympic: false,
                roundIds: nil,
                fightResult: nil,
                blueVideoReplayUsed: false,
                redVideoReplayUsed: false,
                videoId: nil,
                videoURL: nil
            )
            
            firebaseService.saveFight(fight) { result in
                switch result {
                case .success(let fightId):
                    saveFightExpectation.fulfill()
                    var updatedFight = fight
                    updatedFight.id = fightId
                    updatedFight.fightNumber = 2

                    self.firebaseService.updateFight(updatedFight) { result in
                        switch result {
                        case .success:
                            self.firebaseService.getFight(id: fightId) { result in
                                switch result {
                                case .success(let retrievedFight):
                                    XCTAssertEqual(retrievedFight.fightNumber, 2, "Fight number should be updated to 2")
                                    updateFightExpectation.fulfill()
                                case .failure(let error):
                                    XCTFail("Failed to get updated fight: \(error.localizedDescription)")
                                }
                            }
                        case .failure(let error):
                            XCTFail("Failed to update fight: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    XCTFail("Failed to save fight: \(error.localizedDescription)")
                }
            }
        } else {
            XCTFail("User not authenticated")
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    // MARK: - Test deleteFight function
   /* func testDeleteFight() {
        let saveFightExpectation = self.expectation(description: "Save fight")
        let deleteFightExpectation = self.expectation(description: "Delete fight")

        let fight = Fight(
            creatorUserId: "testUser",
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            roundIds: nil,
            fightResult: nil,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false,
            videoId: nil,
            videoURL: nil
        )
        
        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                saveFightExpectation.fulfill()
                var fightToDelete = fight
                fightToDelete.id = fightId
                self.firebaseService.deleteFight(fightToDelete) { result in
                    switch result {
                    case .success:
                        deleteFightExpectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to delete fight: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
  }
    */
    // MARK: - Test getFightsForEvent function
    func test12_testGetFightsForEvent() {
        let expectation = self.expectation(description: "Get fights for event")
        
        firebaseService.getFightsForEvent(eventId: "testEventId") { result in
            switch result {
            case .success(let fights):
                XCTAssertNotNil(fights, "Fights list should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to get fights for event: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    func testGetFighters() {
        let expectation = self.expectation(description: "Get fighters")
        
        // Create a unique fighter
        let uniqueId = UUID().uuidString
        let fighter = Fighter(
            id: nil,
            creatorUserId: "testUser_\(uniqueId)",
            firstName: "John_\(uniqueId)",
            lastName: "Doe",
            gender: "Male",
            birthdate: Date(),
            country: "USA",
            profileImageURL: nil,
            fightIds: nil
        )
        
        // Save the fighter
        firebaseService.saveFighter(fighter) { result in
            switch result {
            case .success(let fighterId):
                // Now get the fighters
                self.firebaseService.getFighters { result in
                    switch result {
                    case .success(let fighters):
                        XCTAssertFalse(fighters.isEmpty, "Fighters list should not be empty")
                        // Verify that the created fighter is in the list
                        let createdFighter = fighters.first { $0.id == fighterId }
                        XCTAssertNotNil(createdFighter, "Created fighter should be in the list")
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to get fighters: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fighter: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }

    // MARK: - Test getFighter function
    
    func test10_testGetFighter() {
        let saveFighterExpectation = self.expectation(description: "Save fighter")
        let getFighterExpectation = self.expectation(description: "Get fighter")
        
        let fighter = Fighter(
            creatorUserId: "testUser",
            firstName: "Jane",
            lastName: "Doe",
            gender: "Female",
            birthdate: Date(),
            country: "Canada",
            profileImageURL: nil,
            fightIds: nil
        )
        
        // Save a fighter first
        firebaseService.saveFighter(fighter) { result in
            switch result {
            case .success:
                saveFighterExpectation.fulfill()
                
                // Now try to get the fighter
                self.firebaseService.getFighters { result in
                    switch result {
                    case .success(let fighters):
                        guard let savedFighter = fighters.first else {
                            XCTFail("No fighters found")
                            return
                        }
                        
                        // Retrieve fighter by ID
                        self.firebaseService.getFighter(id: savedFighter.id!) { result in
                            switch result {
                            case .success(let retrievedFighter):
                                XCTAssertEqual(retrievedFighter.firstName, "Jane")
                                XCTAssertEqual(retrievedFighter.lastName, "Doe")
                                XCTAssertEqual(retrievedFighter.gender, "Female")
                                XCTAssertEqual(retrievedFighter.country, "Canada")
                                getFighterExpectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to get fighter: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to get fighters: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fighter: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    // MARK: - Test upLoadFighterImage function

    func testUploadFighterImage() {
        let expectation = self.expectation(description: "Upload fighter image")

        // Load a sample image from the test bundle or create a dummy image
        guard let image = UIImage(named: "user_avatar", in: Bundle(for: type(of: self)), compatibleWith: nil) else {
            XCTFail("Failed to load image from test bundle")
            return
        }

        // Call the uploadFighterImage method
        firebaseService.uploadFighterImage(image) { result in
            switch result {
            case .success(let url):
                XCTAssertNotNil(url, "URL for uploaded image should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to upload fighter image: \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    // MARK: - Test updateFighterWithFight function
    
    func test7_testUpdateFighterWithFight() {
        let expectation = self.expectation(description: "Update fighter with fight")
        
        // Create a fighter
        let fighter = Fighter(
            creatorUserId: "testUser",
            firstName: "Alex",
            lastName: "Smith",
            gender: "men",
            birthdate: Date(),
            country: "UK",
            profileImageURL: nil,
            fightIds: nil
        )
        
        // Save the fighter first
        firebaseService.saveFighter(fighter) { result in
            switch result {
            case .success(let savedFighterId):  // Capture the saved ID
                let fighterId = savedFighterId
                
                // Now update this fighter with a new fight
                self.firebaseService.updateFighterWithFight(fighterId: fighterId , fightId: "1") { result in
                    switch result {
                    case .success:
                        // Verify that the fight was added
                        self.firebaseService.getFighter(id: fighterId) { result in
                            switch result {
                            case .success(let updatedFighter):
                                XCTAssertTrue(updatedFighter.fightIds?.contains("1") ?? false, "Fighter should contain the new fight ID")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to get updated fighter: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to update fighter with fight: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fighter: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }

    // MARK: - Test getEvents function

    func testGetEvents() {
        let expectation = self.expectation(description: "Get events")
        
        // Create a unique event
        let uniqueId = UUID().uuidString
        let event = Event(
            id: nil,
            creatorUserId: "testUser_\(uniqueId)",
            eventName: "Test Event \(uniqueId)",
            eventType: .open,
            location: "New York",
            date: Date(),
            country: "USA"
        )
        
        // Save the event
        firebaseService.saveEvent(event) { result in
            switch result {
            case .success(let eventId):
                // Now get the events
                self.firebaseService.getEvents { result in
                    switch result {
                    case .success(let events):
                        XCTAssertFalse(events.isEmpty, "Event list should not be empty")
                        // Verify that the created event is in the list
                        let createdEvent = events.first { $0.id == eventId }
                        XCTAssertNotNil(createdEvent, "Created event should be in the list")
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to get events: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save event: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }


    // MARK: - Test getEvent function

    func test9_testGetEvent() {
        let saveEventExpectation = self.expectation(description: "Save event")
        let getEventExpectation = self.expectation(description: "Get event")

        let event = Event(
            creatorUserId: "testUser2",
            eventName: "Test Event",
            eventType: .open,
            location: "lyon",
            date: Date(),
            country: "FRANCE"
        )

        // Save event first
        firebaseService.saveEvent(event) { result in
            switch result {
            case .success(let eventId):
                saveEventExpectation.fulfill()

                // Now try to get the event by ID
                self.firebaseService.getEvent(id: eventId) { result in
                    switch result {
                    case .success(let retrievedEvent):
                        XCTAssertEqual(retrievedEvent.eventName, "Test Event")
                        XCTAssertEqual(retrievedEvent.location, "lyon")
                        getEventExpectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to get event: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save event: \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 20, handler: nil)
    }

    // MARK: - Test updateEventWithFight function

        func test6_testUpdateEventWithFight() {
        let expectation = self.expectation(description: "Update event with fight")

        // Create an event
        let event = Event(
            creatorUserId: "testUser",
            eventName: "Fight Event",
            eventType: .open,
            location: "New York",
            date: Date(),
            country: "USA"
        )

        // Save the event first
        firebaseService.saveEvent(event) { result in
            switch result {
            case .success(let eventId):
                // Now update the event with a fight
                self.firebaseService.updateEventWithFight(eventId: eventId, fightId: "testFightId") { result in
                    switch result {
                    case .success:
                        // Verify that the fight was added to the event
                        self.firebaseService.getEvent(id: eventId) { result in
                            switch result {
                            case .success(let updatedEvent):
                                XCTAssertTrue(updatedEvent.fightIds?.contains("testFightId") ?? false, "Event should contain the new fight ID")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to get updated event: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to update event with fight: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save event: \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 20, handler: nil)
    }

    // MARK: - Test uploadEventImage function

    func testUploadEventImage() {
        let expectation = self.expectation(description: "Upload event image")

        guard let image = UIImage(systemName: "photo") else {
            XCTFail("Could not create test image")
            return
        }

        firebaseService.uploadEventImage(image) { result in
            switch result {
            case .success(let url):
                XCTAssertNotNil(url, "URL should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to upload event image: \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testSaveRound() {
        let expectation = self.expectation(description: "Save round")

        let fight = Fight(
            id: nil,  // Assurez-vous que l'ID est nil ici pour que Firestore en génère un nouveau
            creatorUserId: "AcjsHhOdP6KancuTlVVJ9PmuU0dh",
            eventId: "openclassroom",
            fightNumber: 101,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Senior",
            weightCategory: "-68",
            round: "Final",
            isOlympic: false
        )

        // First save the fight
        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                // Now create a round using the saved fight ID
                var savedFight = fight
                savedFight.id = fightId  // Mise à jour de l'ID du combat
                
                let round = Round(
                    id: nil,  // Laissez Firestore générer un nouvel ID
                    fightId: fightId,
                    creatorUserId: "AcjsHhOdP6KancuTlVVJ9PmuU0dh",
                    roundNumber: 1,
                    chronoDuration: 60,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: "blueFighter",
                    redFighterId: "redFighter",
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil
                )

                // Save the round for the created fight
                self.firebaseService.saveRound(round, for: savedFight) { roundResult in
                    switch roundResult {
                    case .success(let roundId):
                        XCTAssertNotNil(roundId, "Round ID should not be nil")
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to save round: \(error.localizedDescription)")
                    }
                }

            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 20, handler: nil)
    }
    func testGetRound() {
        let expectation = self.expectation(description: "Get round")
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            expectation.fulfill()
            return
        }
        
        // Create a unique fight
        let uniqueId = UUID().uuidString
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId_\(uniqueId)",
            fightNumber: 1,
            blueFighterId: "blueFighter_\(uniqueId)",
            redFighterId: "redFighter_\(uniqueId)",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false
        )
        
        // Save the fight
        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId
                
                // Create a round
                var round = Round(
                    id: nil,
                    fightId: fightId,
                    creatorUserId: currentUserID,
                    roundNumber: 1,
                    chronoDuration: 120,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: fight.blueFighterId,
                    redFighterId: fight.redFighterId,
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil
                )
                
                // Save the round
                self.firebaseService.saveRound(round, for: fight) { result in
                    switch result {
                    case .success(let roundId):
                        round.id = roundId
                        
                        // Now get the round
                        self.firebaseService.getRound(id: roundId, for: fight) { result in
                            switch result {
                            case .success(let retrievedRound):
                                XCTAssertNotNil(retrievedRound, "Round should not be nil")
                                XCTAssertEqual(retrievedRound.roundNumber, 1, "Round number should be 1")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to get round: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to save round: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }

    func testGetRoundsForFight() {
        let expectation = self.expectation(description: "Get rounds for fight")
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            expectation.fulfill()
            return
        }
        
        // Create a unique fight
        let uniqueId = UUID().uuidString
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId_\(uniqueId)",
            fightNumber: 1,
            blueFighterId: "blueFighter_\(uniqueId)",
            redFighterId: "redFighter_\(uniqueId)",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            roundIds: []
        )
        
        // Save the fight
        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId
                
                // Create a round associated with the fight
                var round = Round(
                    id: nil,
                    fightId: fightId,
                    creatorUserId: currentUserID,
                    roundNumber: 1,
                    chronoDuration: 120,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: fight.blueFighterId,
                    redFighterId: fight.redFighterId,
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil
                )
                
                // Save the round
                self.firebaseService.saveRound(round, for: fight) { result in
                    switch result {
                    case .success(let roundId):
                        round.id = roundId
                        fight.roundIds?.append(roundId)
                        
                        // Now get rounds for fight
                        self.firebaseService.getRoundsForFight(fight) { result in
                            switch result {
                            case .success(let rounds):
                                XCTAssertNotNil(rounds, "Rounds should not be nil")
                                XCTAssertFalse(rounds.isEmpty, "There should be at least one round")
                                // Verify that the created round is in the list
                                let createdRound = rounds.first { $0.id == roundId }
                                XCTAssertNotNil(createdRound, "Created round should be in the list")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to get rounds: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to save round: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }

    func testUpdateRound() {
        let expectation = self.expectation(description: "Update round")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 123,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Junior",
            weightCategory: "-58",
            round: "16eme",
            isOlympic: false,
            // Initialize other properties as needed
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Manually set the id
                print("Fight saved with ID: \(fightId)")

                // Step 2: Create and save a round
                var round = Round(
                    id: nil,
                    fightId: fightId,
                    creatorUserId: currentUserID,
                    roundNumber: 108,
                    chronoDuration: 120,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: "blueFighter",
                    redFighterId: "redFighter",
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil
                )

                self.firebaseService.saveRound(round, for: fight) { saveResult in
                    switch saveResult {
                    case .success(let roundId):
                        round.id = roundId  // Manually set the id
                        print("Round saved with ID: \(roundId)")

                        // Step 3: Update the round
                        round.duration = 120  // Modify a value to test the update

                        self.firebaseService.updateRound(round, for: fight) { updateResult in
                            switch updateResult {
                            case .success:
                                print("Round updated successfully")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to update round: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to save round: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 30, handler: nil)
    }


    func testDeleteRound() {
        let expectation = self.expectation(description: "Delete round")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 123,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Junior",
            weightCategory: "-58",
            round: "16eme",
            isOlympic: false,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Manually set the id
                print("Fight saved with ID: \(fightId)")

                // Step 2: Create and save a round
                var round = Round(
                    id: nil,
                    fightId: fightId,
                    creatorUserId: currentUserID,
                    roundNumber: 108,
                    chronoDuration: 120,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: "blueFighter",
                    redFighterId: "redFighter",
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil
                )

                self.firebaseService.saveRound(round, for: fight) { saveResult in
                    switch saveResult {
                    case .success(let roundId):
                        round.id = roundId  // Manually set the id
                        print("Round saved with ID: \(roundId)")

                        // Step 3: Delete the round using the actual roundId
                        self.firebaseService.deleteRound(id: roundId, for: fight) { result in
                            switch result {
                            case .success:
                                print("Round deleted successfully")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to delete round: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to save round: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
    func testGetAllRoundsForFight() {
        let expectation = self.expectation(description: "Get all rounds for fight")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Set the id of the fight
                print("Fight saved with ID: \(fightId)")

                // Step 2: Create and save a round associated with the fight
                var round = Round(
                    id: nil,
                    fightId: fightId,
                    creatorUserId: currentUserID,
                    roundNumber: 1,
                    chronoDuration: 120,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: "blueFighter",
                    redFighterId: "redFighter",
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil
                )

                self.firebaseService.saveRound(round, for: fight) { saveResult in
                    switch saveResult {
                    case .success(let roundId):
                        round.id = roundId  // Set the id of the round
                        print("Round saved with ID: \(roundId)")

                        // Step 3: Get all rounds for the fight
                        self.firebaseService.getAllRoundsForFight(fight) { result in
                            switch result {
                            case .success(let rounds):
                                XCTAssertNotNil(rounds, "Rounds should not be nil")
                                XCTAssertFalse(rounds.isEmpty, "There should be at least one round")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to get all rounds: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }

                    case .failure(let error):
                        XCTFail("Failed to save round: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }

            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchUserRounds() {
        let expectation = self.expectation(description: "Fetch user rounds")
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            expectation.fulfill()
            return
        }
        
        // Create a unique fight
        let uniqueId = UUID().uuidString
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId_\(uniqueId)",
            fightNumber: 1,
            blueFighterId: "blueFighter_\(uniqueId)",
            redFighterId: "redFighter_\(uniqueId)",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            roundIds: []
        )
        
        // Save the fight
        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId
                
                // Create a round associated with the fight
                var round = Round(
                    id: nil,
                    fightId: fightId,
                    creatorUserId: currentUserID,
                    roundNumber: 1,
                    chronoDuration: 120,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: fight.blueFighterId,
                    redFighterId: fight.redFighterId,
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil
                )
                
                // Save the round
                self.firebaseService.saveRound(round, for: fight) { result in
                    switch result {
                    case .success(let roundId):
                        round.id = roundId
                        
                        // Now fetch user rounds
                        self.firebaseService.fetchUserRounds { result in
                            switch result {
                            case .success(let rounds):
                                XCTAssertNotNil(rounds, "Rounds should not be nil")
                                XCTAssertFalse(rounds.isEmpty, "There should be at least one round")
                                // Verify that the created round is in the list
                                let createdRound = rounds.first { $0.id == roundId }
                                XCTAssertNotNil(createdRound, "Created round should be in the user's rounds")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to fetch user rounds: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to save round: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }

    func testSaveAction() {
        let expectation = self.expectation(description: "Save action")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            roundIds: [],// Initialize roundIds
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Set the id of the fight
                print("Fight saved with ID: \(fightId)")

                // Step 2: Create and save a round associated with the fight
                var round = Round(
                    id: nil,
                    fightId: fightId,
                    creatorUserId: currentUserID,
                    roundNumber: 1,
                    chronoDuration: 120,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: "blueFighter",
                    redFighterId: "redFighter",
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil
                )

                self.firebaseService.saveRound(round, for: fight) { saveResult in
                    switch saveResult {
                    case .success(let roundId):
                        round.id = roundId  // Set the id of the round
                        print("Round saved with ID: \(roundId)")

                        // Update fight's roundIds
                        if fight.roundIds == nil {
                            fight.roundIds = []
                        }
                        fight.roundIds?.append(roundId)

                        // Step 3: Save the action
                        let action = Action(
                            id: "testAction",
                            fighterId: "blueFighter",
                            color: .blue,
                            actionType: .kick,
                            timeStamp: Date().timeIntervalSince1970,
                            videoTimestamp: 5.0,
                            chronoTimestamp: 1
                        )

                        self.firebaseService.saveAction(action, for: fight, videoTimestamp: 5.0) { result in
                            switch result {
                            case .success:
                                print("Action saved successfully")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to save action: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }

                    case .failure(let error):
                        XCTFail("Failed to save round: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }

            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSaveRoundAndUpdateFight() {
        let expectation = self.expectation(description: "Save round and update fight")

        // Initialize FirebaseService

        // Step 1: Create the fight object
        var fight = Fight(
            id: nil, // Ensure id is initially nil
            creatorUserId: "testUser",
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            roundIds: [],
            fightResult: nil,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false,
            videoId: nil,
            videoURL: nil
        )

        // Save the fight to Firestore
        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Assign the generated id to the fight object

                // Step 2: Create the round object using the fight's id
                let round = Round(
                    id: nil,
                    fightId: fight.id ?? "",
                    creatorUserId: fight.creatorUserId,
                    roundNumber: 1,
                    chronoDuration: 60,
                    duration: 60,
                    roundTime: 60,
                    blueFighterId: "blueFighter",
                    redFighterId: "redFighter",
                    actions: [],
                    videoReplays: [],
                    victoryDecision: nil,
                    roundWinner: nil,
                    blueHits: 0,
                    redHits: 0,
                    startTime: nil,
                    endTime: nil
                )


                // Step 3: Save the round and update the fight
                self.firebaseService.saveRoundAndUpdateFight(round, for: fight) { result in
                    switch result {
                    case .success(let roundId):
                        XCTAssertNotNil(roundId, "Round ID should not be nil")
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to save round and update fight: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGetLastRoundEndTime() {
        let expectation = self.expectation(description: "Get last round end time")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil, // Ensure id is initially nil
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            roundIds: [],
            fightResult: nil,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false,
            videoId: nil,
            videoURL: nil
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId // Assign the generated id to the fight object
                print("Fight saved with ID: \(fightId)")

                // Step 2: Load the video URL from the test bundle
                guard let videoURL = Bundle(for: type(of: self)).url(forResource: "testVideo", withExtension: "mp4") else {
                    XCTFail("Failed to load video from test bundle")
                    expectation.fulfill()
                    return
                }

                // Step 3: Upload the video
                self.firebaseService.uploadVideo(for: fight, videoURL: videoURL, progressHandler: { progress in
                    // You can print or log progress here if needed
                }) { result in
                    switch result {
                    case .success(let video):
                        print("Video uploaded with ID: \(video.id)")

                        // Step 4: Update video timestamps
                         let videoId = video.id
                           
                        let roundNumber = 1
                        let startTimestamp: TimeInterval = 100
                        let endTimestamp: TimeInterval = 150

                        self.firebaseService.updateVideoTimestamps(videoId: videoId, roundNumber: roundNumber, startTimestamp: startTimestamp, endTimestamp: endTimestamp) { result in
                            switch result {
                            case .success:
                                // Step 5: Call getLastRoundEndTime
                                self.firebaseService.getLastRoundEndTime(for: fight) { result in
                                    switch result {
                                    case .success(let endTime):
                                        // Verify that the endTime matches the updated endTimestamp
                                        XCTAssertEqual(endTime, endTimestamp, "End time should match the updated end timestamp")
                                        expectation.fulfill()
                                    case .failure(let error):
                                        XCTFail("Failed to get last round end time: \(error.localizedDescription)")
                                        expectation.fulfill()
                                    }
                                }
                            case .failure(let error):
                                XCTFail("Failed to update video timestamps: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to upload video: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }

            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 60, handler: nil)
    }


    func testUploadVideo() {
        let expectation = self.expectation(description: "Upload video")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Set the id of the fight
                print("Fight saved with ID: \(fightId)")

                // Step 2: Get the video URL
                guard let videoURL = Bundle(for: type(of: self)).url(forResource: "testVideo", withExtension: "mp4") else {
                    XCTFail("Failed to load video from test bundle")
                    return
                }


                // Step 3: Upload the video
                self.firebaseService.uploadVideo(for: fight, videoURL: videoURL, progressHandler: { progress in
                    XCTAssertGreaterThanOrEqual(progress, 0.0, "Progress should be greater than or equal to 0")
                }) { result in
                    switch result {
                    case .success(let video):
                        XCTAssertNotNil(video.url, "Video URL should not be nil")
                        XCTAssertGreaterThan(video.duration, 0, "Video duration should be greater than 0")
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to upload video: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }

            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 60, handler: nil)
    }

    func testGetVideo() {
        let expectation = self.expectation(description: "Get video")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Set the id of the fight
                print("Fight saved with ID: \(fightId)")

                // Step 2: Get the video URL from the test bundle
                guard let videoURL = Bundle(for: type(of: self)).url(forResource: "testVideo", withExtension: "mp4") else {
                    XCTFail("Failed to load video from test bundle")
                    expectation.fulfill()
                    return
                }

                // Step 3: Upload the video
                self.firebaseService.uploadVideo(for: fight, videoURL: videoURL, progressHandler: { progress in
                    // You can print or log progress here if needed
                }) { result in
                    switch result {
                    case .success(let video):
                        print("Video uploaded with ID: \(video.id)")

                        // Step 4: Now test getVideo using the actual videoId
                        self.firebaseService.getVideo(by: video.id) { result in
                            switch result {
                            case .success(let fetchedVideo):
                                XCTAssertEqual(fetchedVideo.id, video.id, "Video ID should match")
                                XCTAssertNotNil(fetchedVideo.url, "Video URL should not be nil")
                                expectation.fulfill()
                            case .failure(let error):
                                XCTFail("Failed to get video: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to upload video: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }

            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 60, handler: nil)
    }

    func testUpdateVideoTimestamps() {
        let expectation = self.expectation(description: "Update video timestamps")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Set the id of the fight
                print("Fight saved with ID: \(fightId)")

                // Step 2: Get the video URL from the test bundle
                guard let videoURL = Bundle(for: type(of: self)).url(forResource: "testVideo", withExtension: "mp4") else {
                    XCTFail("Failed to load video from test bundle")
                    expectation.fulfill()
                    return
                }

                // Step 3: Upload the video
                self.firebaseService.uploadVideo(for: fight, videoURL: videoURL, progressHandler: { progress in
                    // You can print or log progress here if needed
                }) { result in
                    switch result {
                    case .success(let video):
                        print("Video uploaded with ID: \(video.id)")

                        // Step 4: Update video timestamps
                        let videoId = video.id
                        let roundNumber = 1
                        let startTimestamp: TimeInterval = 100
                        let endTimestamp: TimeInterval = 150

                        self.firebaseService.updateVideoTimestamps(videoId: videoId, roundNumber: roundNumber, startTimestamp: startTimestamp, endTimestamp: endTimestamp) { result in
                            switch result {
                            case .success:
                                // Fetch the video to verify the timestamps have been updated
                                self.firebaseService.getVideo(by: videoId) { result in
                                    switch result {
                                    case .success(let updatedVideo):
                                        // Verify that the roundTimestamps have been updated
                                        let matchingTimestamp = updatedVideo.roundTimestamps.first { $0.roundNumber == roundNumber }
                                        XCTAssertNotNil(matchingTimestamp, "Round timestamps should contain the updated round")
                                        XCTAssertEqual(matchingTimestamp?.start, startTimestamp, "Start timestamp should match")
                                        XCTAssertEqual(matchingTimestamp?.end, endTimestamp, "End timestamp should match")
                                        expectation.fulfill()
                                    case .failure(let error):
                                        XCTFail("Failed to get video after updating timestamps: \(error.localizedDescription)")
                                        expectation.fulfill()
                                    }
                                }
                            case .failure(let error):
                                XCTFail("Failed to update video timestamps: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to upload video: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }

            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 60, handler: nil)
    }


    func testUpdateVideoRoundTimestamps() {
        let expectation = self.expectation(description: "Update video round timestamps")

        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save a fight
        var fight = Fight(
            id: nil,
            creatorUserId: currentUserID,
            eventId: "testEventId",
            fightNumber: 1,
            blueFighterId: "blueFighter",
            redFighterId: "redFighter",
            category: "Adult",
            weightCategory: "Lightweight",
            round: "Final",
            isOlympic: false,
            blueVideoReplayUsed: false,
            redVideoReplayUsed: false
        )

        firebaseService.saveFight(fight) { result in
            switch result {
            case .success(let fightId):
                fight.id = fightId  // Set the id of the fight
                print("Fight saved with ID: \(fightId)")

                // Step 2: Get the video URL from the test bundle
                guard let videoURL = Bundle(for: type(of: self)).url(forResource: "testVideo", withExtension: "mp4") else {
                    XCTFail("Failed to load video from test bundle")
                    expectation.fulfill()
                    return
                }

                // Step 3: Upload the video
                self.firebaseService.uploadVideo(for: fight, videoURL: videoURL, progressHandler: { progress in
                    // You can print or log progress here if needed
                }) { result in
                    switch result {
                    case .success(let video):
                        print("Video uploaded with ID: \(video.id)")

                        // Step 4: Update video round timestamps
                        let roundNumber = 1
                        let startTime: TimeInterval = 50.0

                        self.firebaseService.updateVideoRoundTimestamps(for: fight, roundNumber: roundNumber, startTime: startTime) { result in
                            switch result {
                            case .success:
                                // Fetch the video to verify the timestamps have been updated
                                self.firebaseService.getVideo(by: video.id) { result in
                                    switch result {
                                    case .success(let updatedVideo):
                                        // Verify that the roundTimestamps have been updated
                                        if let matchingTimestamp = updatedVideo.roundTimestamps.first(where: { $0.roundNumber == roundNumber }) {
                                            XCTAssertEqual(matchingTimestamp.start, startTime, "Start timestamp should match")
                                            expectation.fulfill()
                                        } else {
                                            XCTFail("Round timestamp not found")
                                            expectation.fulfill()
                                        }
                                    case .failure(let error):
                                        XCTFail("Failed to get video after updating timestamps: \(error.localizedDescription)")
                                        expectation.fulfill()
                                    }
                                }
                            case .failure(let error):
                                XCTFail("Failed to update video round timestamps: \(error.localizedDescription)")
                                expectation.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to upload video: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save fight: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 60, handler: nil)
    }

    func testFetchFilteredFights() async throws {
        let expectation = expectation(description: "Fetch filtered fights")

        // Test parameters
        let fighter = "testFighterId"
        let gender = "Male"
        let fighterNationality = "USA"
        let event = "testEventId"
        let eventType = "open"
        let eventCountry = "USA"
        let ageCategory = "Adult"
        let weightCategory = "Lightweight"
        let isOlympic = false
        let startDate = Date(timeIntervalSince1970: 0)
        let endDate = Date()

        // Call the method
        do {
            let fights = try await firebaseService.fetchFilteredFights(
                fighter: fighter,
                gender: gender,
                fighterNationality: fighterNationality,
                event: event,
                eventType: eventType,
                eventCountry: eventCountry,
                ageCategory: ageCategory,
                weightCategory: weightCategory,
                isOlympic: isOlympic,
                startDate: startDate,
                endDate: endDate
            )

            // Validate the results
            XCTAssertNotNil(fights, "Fights should not be nil")
            XCTAssertGreaterThanOrEqual(fights.count, 0, "There should be at least 0 fights returned")

            expectation.fulfill()
        } catch {
            XCTFail("Failed to fetch filtered fights: \(error.localizedDescription)")
        }

        await fulfillment(of: [expectation], timeout: 10)
    }

    func testFetchRounds() async throws {
        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Step 1: Create and save Fighters
        var blueFighter = Fighter(
            id: nil,
            creatorUserId: currentUserID,
            firstName: "Blue",
            lastName: "Fighter",
            gender: "Male",
            birthdate: Date(),
            country: "CountryA",
            profileImageURL: nil,
            fightIds: []
        )

        var redFighter = Fighter(
            id: nil,
            creatorUserId: currentUserID,
            firstName: "Red",
            lastName: "Fighter",
            gender: "Female",
            birthdate: Date(),
            country: "CountryB",
            profileImageURL: nil,
            fightIds: []
        )

        do {
            // Save Fighters
            let blueFighterId = try await firebaseService.saveFighterAsync(blueFighter)
            blueFighter.id = blueFighterId
            let redFighterId = try await firebaseService.saveFighterAsync(redFighter)
            redFighter.id = redFighterId

            // Step 2: Create and save an Event
            var event = Event(
                id: nil,
                creatorUserId: currentUserID,
                eventName: "Test Event",
                eventType: .open, // Replace with appropriate EventType
                location: "Test Location",
                date: Date(),
                imageURL: nil,
                fightIds: [],
                country: "Test Country"
            )

            let eventId = try await firebaseService.saveEventAsync(event)
            event.id = eventId

            // Step 3: Create and save a Fight
            var fight = Fight(
                id: nil,
                creatorUserId: currentUserID,
                eventId: eventId,
                fightNumber: 1,
                blueFighterId: blueFighterId,
                redFighterId: redFighterId,
                category: "Adult",
                weightCategory: "Lightweight",
                round: "Final",
                isOlympic: false,
                roundIds: [],
                fightResult: nil,
                blueVideoReplayUsed: false,
                redVideoReplayUsed: false,
                videoId: nil,
                videoURL: nil
            )

            let fightId = try await firebaseService.saveFightAsync(fight)
            fight.id = fightId

            // Step 4: Create and save rounds
            var round1 = Round(
                id: nil,
                fightId: fightId,
                creatorUserId: currentUserID,
                roundNumber: 1,
                chronoDuration: 120,
                duration: 60,
                roundTime: 60,
                blueFighterId: blueFighterId,
                redFighterId: redFighterId,
                actions: [],
                videoReplays: [],
                victoryDecision: nil
            )

            var round2 = Round(
                id: nil,
                fightId: fightId,
                creatorUserId: currentUserID,
                roundNumber: 2,
                chronoDuration: 120,
                duration: 60,
                roundTime: 60,
                blueFighterId: blueFighterId,
                redFighterId: redFighterId,
                actions: [],
                videoReplays: [],
                victoryDecision: nil
            )

            let roundId1 = try await firebaseService.saveRoundAsync(round1, for: fight)
            round1.id = roundId1
            let roundId2 = try await firebaseService.saveRoundAsync(round2, for: fight)
            round2.id = roundId2

            // Update fight's roundIds
            fight.roundIds = [roundId1, roundId2]

            // Now call fetchRounds
            let rounds = try await self.firebaseService.fetchRounds(for: fight)

            // Validate the results
            XCTAssertNotNil(rounds, "Rounds should not be nil")
            XCTAssertEqual(rounds.count, 2, "There should be exactly 2 rounds returned")
        } catch {
            XCTFail("Test failed with error: \(error.localizedDescription)")
        }
    }



    func testFetchEvents() async throws {
        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Create event objects
        var event1 = Event(
            id: nil,
            creatorUserId: currentUserID,
            eventName: "Test Event 1",
            eventType: .open, // Replace with appropriate EventType
            location: "Test Location 1",
            date: Date(),
            imageURL: nil,
            fightIds: [],
            country: "CountryA"
        )

        var event2 = Event(
            id: nil,
            creatorUserId: currentUserID,
            eventName: "Test Event 2",
            eventType: .open, // Replace with appropriate EventType
            location: "Test Location 2",
            date: Date(),
            imageURL: nil,
            fightIds: [],
            country: "CountryB"
        )

        do {
            // Save events asynchronously
            let eventId1 = try await firebaseService.saveEventAsync(event1)
            event1.id = eventId1
            let eventId2 = try await firebaseService.saveEventAsync(event2)
            event2.id = eventId2

            // Now fetch events asynchronously
            let eventIds = [eventId1, eventId2]
            let events = try await firebaseService.fetchEventsAsync(withIds: eventIds)

            // Validate the results
            XCTAssertEqual(events.count, 2, "There should be exactly 2 events returned")
        } catch {
            XCTFail("Failed to save events or fetch events: \(error.localizedDescription)")
        }
    }


    func testFetchFighters() async throws {
        // Ensure a user is logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            XCTFail("No authenticated user")
            return
        }

        // Create fighter objects
        var fighter1 = Fighter(
            id: nil,
            creatorUserId: currentUserID,
            firstName: "First",
            lastName: "Fighter1",
            gender: "Male",
            birthdate: Date(), // Use appropriate date
            country: "CountryA",
            profileImageURL: nil,
            fightIds: []
        )

        var fighter2 = Fighter(
            id: nil,
            creatorUserId: currentUserID,
            firstName: "Second",
            lastName: "Fighter2",
            gender: "Female",
            birthdate: Date(), // Use appropriate date
            country: "CountryB",
            profileImageURL: nil,
            fightIds: []
        )

        do {
            // Save fighters asynchronously
            let fighterId1 = try await firebaseService.saveFighterAsync(fighter1)
            fighter1.id = fighterId1
            let fighterId2 = try await firebaseService.saveFighterAsync(fighter2)
            fighter2.id = fighterId2

            // Now fetch fighters asynchronously
            let fighterIds = [fighterId1, fighterId2]
            let fighters = try await firebaseService.fetchFighters(ids: fighterIds)

            // Validate the results
            XCTAssertNotNil(fighters, "Fighters should not be nil")
            XCTAssertEqual(fighters.count, 2, "There should be exactly 2 fighters returned")
        } catch {
            XCTFail("Failed to save fighters or fetch fighters: \(error.localizedDescription)")
        }
    }



}


extension XCTestCase {

    func clearFirestore(completion: @escaping () -> Void) {
        let projectId = FirebaseApp.app()!.options.projectID!
        let url = URL(string: "http://localhost:8080/emulator/v1/projects/\(projectId)/databases/(default)/documents")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error clearing Firestore: \(error.localizedDescription)")
            } else if let response = response as? HTTPURLResponse {
                print("Firestore cleared, status code: \(response.statusCode)")
            }
            completion()
        }
        task.resume()
    }

    func clearStorage(completion: @escaping () -> Void) {
        let storageBucket = "test-bucket"  // Replace with your actual bucket name if different
        let url = URL(string: "http://localhost:9199/storage/v1/b/\(storageBucket)/o?prefix=")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET" // First, list the objects

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Error listing storage objects: \(error?.localizedDescription ?? "Unknown error")")
                completion()
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let items = json?["items"] as? [[String: Any]] ?? []

                let group = DispatchGroup()

                for item in items {
                    if let name = item["name"] as? String {
                        group.enter()
                        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
                        let deleteUrl = URL(string: "http://localhost:9199/storage/v1/b/\(storageBucket)/o/\(encodedName)")!
                        var deleteRequest = URLRequest(url: deleteUrl)
                        deleteRequest.httpMethod = "DELETE"
                        let deleteTask = URLSession.shared.dataTask(with: deleteRequest) { _, _, _ in
                            print("Deleted storage object: \(name)")
                            group.leave()
                        }
                        deleteTask.resume()
                    }
                }
                group.notify(queue: .main) {
                    print("All storage objects deleted")
                    completion()
                }
            } catch {
                print("Error parsing storage objects: \(error.localizedDescription)")
                completion()
            }
        }
        task.resume()
    }

    func clearAuth(completion: @escaping () -> Void) {
        let projectId = FirebaseApp.app()!.options.projectID!
        let url = URL(string: "http://localhost:9099/emulator/v1/projects/\(projectId)/accounts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET" // First, list the accounts

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Error listing authentication users: \(error?.localizedDescription ?? "Unknown error")")
                completion()
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let users = json?["users"] as? [[String: Any]] ?? []

                let group = DispatchGroup()

                for user in users {
                    if let localId = user["localId"] as? String {
                        group.enter()
                        let deleteUrl = URL(string: "http://localhost:9099/emulator/v1/projects/\(projectId)/accounts:delete")!
                        var deleteRequest = URLRequest(url: deleteUrl)
                        deleteRequest.httpMethod = "POST"
                        deleteRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        let body = ["localId": localId]
                        deleteRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)

                        let deleteTask = URLSession.shared.dataTask(with: deleteRequest) { _, _, _ in
                            print("Deleted auth user: \(localId)")
                            group.leave()
                        }
                        deleteTask.resume()
                    }
                }
                group.notify(queue: .main) {
                    print("All auth users deleted")
                    completion()
                }
            } catch {
                print("Error parsing authentication users: \(error.localizedDescription)")
                completion()
            }
        }
        task.resume()
    }

    func clearEmulators(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        clearFirestore {
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        clearStorage {
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        clearAuth {
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            print("All emulators cleared")
            completion()
        }
    }
}
