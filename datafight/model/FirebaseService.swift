import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit
import FirebaseAuth
import Network
import AVFoundation


class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private let monitor = NWPathMonitor()
    private var isConnected = true
    
    private func getCurrentUserID() -> Result<String, Error> {
        if let uid = Auth.auth().currentUser?.uid {
            return .success(uid)
        } else {
            return .failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
        }
    }
    
    func saveFighter(_ fighter: Fighter, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        var fighterData = fighter
        fighterData.creatorUserId = uid  // Assurez-vous que l'ID de l'utilisateur est défini
        
        do {
            let _ = try db.collection("fighters").addDocument(from: fighterData)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func getFighters(completion: @escaping (Result<[Fighter], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        db.collection("fighters")
            .whereField("creatorUserId", isEqualTo: uid)
            .getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let fighters = querySnapshot?.documents.compactMap { document -> Fighter? in
                    var fighter = try? document.data(as: Fighter.self)
                    fighter?.id = document.documentID  // Assigner l'ID du document à l'objet Fighter
                    return fighter
                } ?? []
                completion(.success(fighters))
            }
        }
    }
    
    func getFighter(id: String, completion: @escaping (Result<Fighter, Error>) -> Void) {
        print("Getting fighter with ID: \(id)")
        db.collection("fighters").document(id).getDocument { (document, error) in
            if let error = error {
                print("Error fetching fighter: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let document = document, document.exists {
                do {
                    var fighter = try document.data(as: Fighter.self)
                    fighter.id = document.documentID
                    print("Successfully fetched fighter: \(fighter.firstName) \(fighter.lastName)")
                    completion(.success(fighter))
                } catch {
                    print("Error parsing fighter: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } else {
                print("Fighter document does not exist")
                completion(.failure(NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fighter not found"])))
            }
        }
    }

    func uploadFighterImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get image data"])))
            return
        }
        
        let imageName = UUID().uuidString
        let imageRef = storage.child("fighter_images/\(imageName).jpg")
        
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                imageRef.downloadURL { (url, error) in
                    if let url = url {
                        completion(.success(url))
                    } else if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                    }
                }
            }
        }
    }
    
    func getUserProfile(completion: @escaping (Result<User, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        db.collection("users").document(uid).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                do {
                    var user = try document.data(as: User.self)
                    user.id = uid
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            } else {
                // L'utilisateur n'existe pas encore dans Firestore, créez un nouveau profil
                let newUser = User(id: uid, firstName: "", lastName: "", dateOfBirth: Date(), role: "", teamName: "", country: "", profileImageURL: nil)
                self.updateUserProfile(newUser) { result in
                    switch result {
                    case .success:
                        completion(.success(newUser))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func updateUserProfile(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        switch getCurrentUserID() {
        case .success(let uid):
            do {
                var userData: [String: Any] = [
                    "firstName": user.firstName,
                    "lastName": user.lastName,
                    "role": user.role,
                    "teamName": user.teamName,
                    "country": user.country
                ]
                
                if let dateOfBirth = user.dateOfBirth {
                    userData["dateOfBirth"] = Timestamp(date: dateOfBirth)
                }
                
                if let profileImageURL = user.profileImageURL {
                    userData["profileImageURL"] = profileImageURL
                }
                print("User data to update: \(userData)")

                db.collection("users").document(uid).setData(userData, merge: true) { error in
                    if let error = error {
                        print("Error updating user data: \(error.localizedDescription)")

                        completion(.failure(error))
                    } else {
                        print("User data updated successfully")

                        completion(.success(()))
                    }
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        switch getCurrentUserID() {
        case .success(let uid):
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                completion(.failure(NSError(domain: "FirebaseService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare image data"])))
                return
            }
            
            let imageRef = storage.child("profile_images/\(uid).jpg")
            imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    imageRef.downloadURL { (url, error) in
                        if let url = url {
                            completion(.success(url))
                        } else if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.failure(NSError(domain: "FirebaseService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                        }
                    }
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "FirebaseService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to convert object to dictionary"])
        }
        return dictionary
    }
}

extension FirebaseService {
    func uploadEventImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get image data"])))
            return
        }
        
        let imageName = UUID().uuidString
        let imageRef = storage.child("event_images/\(imageName).jpg")
        
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                imageRef.downloadURL { (url, error) in
                    if let url = url {
                        completion(.success(url))
                    } else if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                    }
                }
            }
        }
    }

    func saveEvent(_ event: Event, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            if let id = event.id {
                try db.collection("events").document(id).setData(from: event)
                completion(.success(id))
            } else {
                let newDocRef = db.collection("events").document()
                var newEvent = event
                newEvent.id = newDocRef.documentID
                try newDocRef.setData(from: newEvent)
                completion(.success(newDocRef.documentID))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func getEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        db.collection("events")
            .whereField("creatorUserId", isEqualTo: uid)
            .getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let events = querySnapshot?.documents.compactMap { document -> Event? in
                    var event = try? document.data(as: Event.self)
                    event?.id = document.documentID  // Assigner l'ID du document à l'objet Event
                    return event
                } ?? []
                completion(.success(events))
            }
        }
    }
    func getEvent(id: String, completion: @escaping (Result<Event, Error>) -> Void) {
        print("Getting event with ID: \(id)")
        db.collection("events").document(id).getDocument { (document, error) in
            if let error = error {
                print("Error fetching event: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let document = document, document.exists {
                do {
                    var event = try document.data(as: Event.self)
                    event.id = document.documentID
                    print("Successfully fetched event: \(event.eventName)")
                    completion(.success(event))
                } catch {
                    print("Error parsing event: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } else {
                print("Event document does not exist")
                completion(.failure(NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Event not found"])))
            }
        }
    }
}
extension FirebaseService {
    func saveFight(_ fight: Fight, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        var fightToSave = fight
        fightToSave.creatorUserId = uid

        do {
            if let id = fightToSave.id {
                try db.collection("fights").document(id).setData(from: fightToSave)
                completion(.success(id))
            } else {
                let newDocRef = db.collection("fights").document()
                fightToSave.id = newDocRef.documentID
                try newDocRef.setData(from: fightToSave)
                completion(.success(newDocRef.documentID))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateFight(_ fight: Fight, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let uid = Auth.auth().currentUser?.uid, uid == fight.creatorUserId else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authorized"])))
                return
            }

            guard let fightId = fight.id else {
                completion(.failure(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fight ID is missing"])))
                return
            }

            if isConnected {
                do {
                    try db.collection("fights").document(fightId).setData(from: fight) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            CoreDataManager.shared.saveFight(fight)
                            completion(.success(()))
                        }
                    }
                } catch {
                    CoreDataManager.shared.saveFight(fight)
                    completion(.failure(error))
                }
            } else {
                CoreDataManager.shared.saveFight(fight)
                completion(.success(()))
            }
        }

    func getFight(id: String, completion: @escaping (Result<Fight, Error>) -> Void) {
        db.collection("fights").document(id).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                do {
                    let fight = try document.data(as: Fight.self)
                    completion(.success(fight))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fight not found"])))
            }
        }
    }

    func getFightsForEvent(eventId: String, completion: @escaping (Result<[Fight], Error>) -> Void) {
        db.collection("fights")
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let fights = querySnapshot?.documents.compactMap { document -> Fight? in
                        try? document.data(as: Fight.self)
                    } ?? []
                    completion(.success(fights))
                }
            }
    }
    func getAllRoundsForFight(_ fight: Fight, completion: @escaping (Result<[Round], Error>) -> Void) {
        guard let fightId = fight.id else {
            completion(.failure(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fight ID is missing"])))
            return
        }

        db.collection("fights").document(fightId).collection("rounds").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let rounds = querySnapshot?.documents.compactMap { document -> Round? in
                    try? document.data(as: Round.self)
                } ?? []
                completion(.success(rounds))
            }
        }
    }

    func updateFighterWithFight(fighterId: String, fightId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let fighterRef = db.collection("fighters").document(fighterId)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let fighterDocument: DocumentSnapshot
            do {
                try fighterDocument = transaction.getDocument(fighterRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard var fighter = try? fighterDocument.data(as: Fighter.self) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch fighter"])
                errorPointer?.pointee = error
                return nil
            }

            fighter.fightIds = (fighter.fightIds ?? []) + [fightId]
            
            do {
                try transaction.setData(from: fighter, forDocument: fighterRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }) { (object, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func updateEventWithFight(eventId: String, fightId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let eventRef = db.collection("events").document(eventId)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let eventDocument: DocumentSnapshot
            do {
                try eventDocument = transaction.getDocument(eventRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard var event = try? eventDocument.data(as: Event.self) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch event"])
                errorPointer?.pointee = error
                return nil
            }

            event.fightIds = (event.fightIds ?? []) + [fightId]
            
            do {
                try transaction.setData(from: event, forDocument: eventRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }) { (object, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    func getFights(completion: @escaping (Result<[Fight], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        print("Starting getFights for user: \(uid)")
        db.collection("fights")
            .whereField("creatorUserId", isEqualTo: uid)
            .getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching fights: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Successfully fetched documents")
                let fights = querySnapshot?.documents.compactMap { document -> Fight? in
                    print("Processing document: \(document.documentID)")
                    do {
                        var fight = try document.data(as: Fight.self)
                        fight.id = document.documentID
                        print("Successfully parsed fight: \(fight)")
                        return fight
                    } catch {
                        print("Error parsing fight: \(error.localizedDescription)")
                        return nil
                    }
                } ?? []
                print("Parsed \(fights.count) fights")
                completion(.success(fights))
            }
        }
    }
}

extension FirebaseService {


    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            if self?.isConnected == true {
                self?.syncUnsyncedData()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    private func syncUnsyncedData() {
        syncCachedRounds { result in
            switch result {
            case .success:
                print("Successfully synced cached rounds")
            case .failure(let error):
                print("Failed to sync cached rounds: \(error.localizedDescription)")
            }
        }
    }

    func saveAction(_ action: Action, for fight: Fight, videoTimestamp: TimeInterval, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let roundId = fight.roundIds?.last else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No active round"])))
                return
            }
            
            // Ajouter le timestamp vidéo à l'action
            var actionWithTimestamp = action
            actionWithTimestamp.videoTimestamp = videoTimestamp
            
            let batch = db.batch()
            
            // Mise à jour du round avec la nouvelle action
            let roundRef = db.collection("rounds").document(roundId)
            batch.updateData(["actions": FieldValue.arrayUnion([actionWithTimestamp.dictionary])], forDocument: roundRef)
            
            // Mise à jour du document vidéo avec le nouveau timestamp d'action
            if let videoId = fight.videoId {
                let videoRef = db.collection("videos").document(videoId)
                batch.updateData([
                    "actionTimestamps": FieldValue.arrayUnion([[
                        "actionId": action.id,
                        "timestamp": videoTimestamp
                    ]])
                ], forDocument: videoRef)
            }
            
            // Exécuter le batch
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
        
        func saveRound(_ round: Round, for fight: Fight, completion: @escaping (Result<String, Error>) -> Void) {
            let roundRef: DocumentReference
            if let id = round.id {
                roundRef = db.collection("rounds").document(id)
            } else {
                roundRef = db.collection("rounds").document()
            }
            
            var roundData = round.dictionary
            roundData["id"] = roundRef.documentID
            
            let batch = db.batch()
            
            // Sauvegarder ou mettre à jour le round
            batch.setData(roundData, forDocument: roundRef, merge: true)
            
            // Mettre à jour le fight avec le nouveau roundId si nécessaire
            if round.id == nil {
                let fightRef = db.collection("fights").document(fight.id ?? "")
                batch.updateData(["roundIds": FieldValue.arrayUnion([roundRef.documentID])], forDocument: fightRef)
            }
            
            // Exécuter le batch
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(roundRef.documentID))
                }
            }
        }
    func saveRoundAndUpdateFight(_ round: Round, for fight: Fight, completion: @escaping (Result<String, Error>) -> Void) {
           let batch = db.batch()
           
           // Reference to the new round document
           let roundRef: DocumentReference
           if let id = round.id {
               roundRef = db.collection("rounds").document(id)
           } else {
               roundRef = db.collection("rounds").document()
           }
           
           var roundData = round.dictionary
           roundData["id"] = roundRef.documentID
           
           // Save or update the round
           batch.setData(roundData, forDocument: roundRef, merge: true)
           
           // Reference to the fight document
           let fightRef = db.collection("fights").document(fight.id ?? "")
           
           // Update fight with new roundId if necessary
           if round.id == nil {
               batch.updateData(["roundIds": FieldValue.arrayUnion([roundRef.documentID])], forDocument: fightRef)
           }
           
           // Check if the round result ends the fight
           if let victoryDecision = round.victoryDecision,
              ["KO", "TKO", "DSQ"].contains(victoryDecision.rawValue) {
               
               let winner = round.roundWinner == fight.blueFighterId ? "blue" : "red"
               let fightResult = FightResult(
                   winner: round.roundWinner ?? "",
                   method: victoryDecision.rawValue,
                   totalScore: (blue: round.blueScore, red: round.redScore)
               )
               
               // Update fight with the result
               batch.updateData([
                   "fightResult": fightResult.dictionary,
                   "isCompleted": true
               ], forDocument: fightRef)
           }
           
           // Commit the batch
           batch.commit { error in
               if let error = error {
                   completion(.failure(error))
               } else {
                   completion(.success(roundRef.documentID))
               }
           }
       }
        func updateVideoTimestamps(videoId: String, roundNumber: Int, startTimestamp: TimeInterval, endTimestamp: TimeInterval?, completion: @escaping (Result<Void, Error>) -> Void) {
            let videoRef = db.collection("videos").document(videoId)
            
            var timestampData: [String: Any] = [
                "roundNumber": roundNumber,
                "start": startTimestamp
            ]
            
            if let endTimestamp = endTimestamp {
                timestampData["end"] = endTimestamp
            }
            
            videoRef.updateData([
                "roundTimestamps": FieldValue.arrayUnion([timestampData])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }

    func getRound(id: String, for fight: Fight, completion: @escaping (Result<Round, Error>) -> Void) {
        print("GetRound called with ID: \(id)")
        print("Fight details:")
        print("  Fight ID: \(fight.id ?? "unknown")")
        print("  Creator User ID: \(fight.creatorUserId)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user")
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])))
            return
        }
        
        print("Authenticated User ID: \(uid)")
        
        if isConnected {
            print("Device is connected. Attempting to fetch from Firestore.")
            let roundRef = db.collection("rounds").document(id)
            print("Firestore reference path: \(roundRef.path)")
            
            roundRef.getDocument { (document, error) in
                if let error = error {
                    print("Error fetching round from Firestore: \(error.localizedDescription)")
                    self.getFallbackRound(id: id, for: fight, completion: completion)
                } else if let document = document, document.exists {
                    print("Round document found in Firestore")
                    do {
                        var round = try document.data(as: Round.self)
                        round.id = document.documentID
                        print("Successfully decoded round:")
                        print("  Round ID: \(round.id ?? "unknown")")
                        print("  Round Number: \(round.roundNumber)")
                        print("  Round Duration: \(round.duration)")
                        CoreDataManager.shared.saveRound(round, for: fight)
                        completion(.success(round))
                    } catch {
                        print("Error decoding round data: \(error.localizedDescription)")
                        self.getFallbackRound(id: id, for: fight, completion: completion)
                    }
                } else {
                    print("Round document not found in Firestore")
                    self.getFallbackRound(id: id, for: fight, completion: completion)
                }
            }
        } else {
            print("Device is offline. Attempting to fetch from Core Data.")
            self.getFallbackRound(id: id, for: fight, completion: completion)
        }
    }

    private func getFallbackRound(id: String, for fight: Fight, completion: @escaping (Result<Round, Error>) -> Void) {
        if let cachedRound = CoreDataManager.shared.getRound(id: id, for: fight) {
            print("Found cached round:")
            print("  Round ID: \(cachedRound.id ?? "unknown")")
            print("  Round Number: \(cachedRound.roundNumber)")
            print("  Round Duration: \(cachedRound.duration)")
            completion(.success(cachedRound))
        } else {
            print("No cached round found")
            completion(.failure(NSError(domain: "FirebaseService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Round not found"])))
        }
    }

    func getRoundsForFight(_ fight: Fight, completion: @escaping (Result<[Round], Error>) -> Void) {
        print("Starting getRoundsForFight for fight ID: \(fight.id ?? "unknown")")
        
        guard let uid = Auth.auth().currentUser?.uid, uid == fight.creatorUserId else {
           
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authorized"])))
            return
        }

        guard let roundIds = fight.roundIds, !roundIds.isEmpty else {
            print("No round IDs found for fight")
            completion(.success([]))
            return
        }

        print("Found \(roundIds.count) round IDs for fight")

        if isConnected {
            print("Device is connected. Fetching rounds from Firebase")
            let group = DispatchGroup()
            var rounds: [Round] = []
            var fetchError: Error?

            for roundId in roundIds {
                group.enter()
                print("Fetching round with ID: \(roundId)")
                db.collection("fights").document(fight.id!).collection("rounds").document(roundId).getDocument { (document, error) in
                    defer { group.leave() }
                    if let error = error {
                        print("Error fetching round \(roundId): \(error.localizedDescription)")
                        fetchError = error
                    } else if let document = document, document.exists {
                        do {
                            var round = try document.data(as: Round.self)
                            round.id = document.documentID
                            rounds.append(round)
                            print("Successfully fetched and added round \(roundId)")
                            CoreDataManager.shared.saveRound(round, for: fight)
                            print("Saved round \(roundId) to Core Data")
                        } catch {
                            print("Error decoding round \(roundId): \(error.localizedDescription)")
                            fetchError = error
                        }
                    } else {
                        print("Round document \(roundId) does not exist")
                    }
                }
            }

            group.notify(queue: .main) {
                if let error = fetchError {
                    print("Error occurred while fetching rounds: \(error.localizedDescription)")
                    let cachedRounds = CoreDataManager.shared.getRoundsForFight(fight)
                    print("Returning \(cachedRounds.count) cached rounds")
                    completion(.success(cachedRounds))
                } else {
                    let sortedRounds = rounds.sorted { $0.roundNumber < $1.roundNumber }
                    print("Successfully fetched all rounds. Returning \(sortedRounds.count) rounds")
                    completion(.success(sortedRounds))
                }
            }
        } else {
            print("Device is not connected. Fetching rounds from Core Data")
            let cachedRounds = CoreDataManager.shared.getRoundsForFight(fight)
            print("Returning \(cachedRounds.count) cached rounds")
            completion(.success(cachedRounds))
        }
    }

    func updateRound(_ round: Round, for fight: Fight, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid, uid == fight.creatorUserId else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authorized"])))
            return
        }

        guard let id = round.id else {
            completion(.failure(NSError(domain: "FirebaseService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Round ID is missing"])))
            return
        }

        if isConnected {
            do {
                try db.collection("fights").document(fight.id!).collection("rounds").document(id).setData(from: round)
                CoreDataManager.shared.saveRound(round, for: fight)
                completion(.success(()))
            } catch {
                CoreDataManager.shared.saveRound(round, for: fight)
                completion(.failure(error))
            }
        } else {
            CoreDataManager.shared.saveRound(round, for: fight)
            completion(.success(()))
        }
    }

    func deleteRound(id: String, for fight: Fight, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid, uid == fight.creatorUserId else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authorized"])))
            return
        }

        if isConnected {
            db.collection("fights").document(fight.id!).collection("rounds").document(id).delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    CoreDataManager.shared.deleteRound(id: id, for: fight)
                    completion(.success(()))
                }
            }
        } else {
            CoreDataManager.shared.deleteRound(id: id, for: fight)
            completion(.success(()))
        }
    }

    func syncCachedRounds(completion: @escaping (Result<Void, Error>) -> Void) {
        let unsyncedRounds = CoreDataManager.shared.getUnsyncedRounds()
        let group = DispatchGroup()

        for round in unsyncedRounds {
            group.enter()
            if let fight = CoreDataManager.shared.getFightForRound(round) {
                saveRound(round, for: fight) { result in
                    switch result {
                    case .success:
                        CoreDataManager.shared.markRoundAsSynced(id: round.id!, for: fight)
                    case .failure(let error):
                        print("Failed to sync round: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            } else {
                print("Failed to find fight for round: \(round.id ?? "unknown")")
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(.success(()))
        }
    }
}

extension FirebaseService {
    func uploadVideo(for fight: Fight, videoURL: URL, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<Video, Error>) -> Void) {
        let videoId = UUID().uuidString
        let storageRef = storage.child("videos/\(videoId).mp4")

        // Début de l'upload
        let uploadTask = storageRef.putFile(from: videoURL, metadata: nil)

        // Suivi de la progression
        uploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                let percentage = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                progressHandler(percentage)
            }
        }

        // Gestion de l'achèvement de l'upload
        uploadTask.observe(.success) { snapshot in
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }

                // Récupérer la durée de la vidéo
                let asset = AVAsset(url: videoURL)
                Task {
                    do {
                        let duration = try await asset.load(.duration)
                        let durationInSeconds = CMTimeGetSeconds(duration)

                        let video = Video(
                            id: videoId,
                            fightId: fight.id ?? "",
                            url: downloadURL.absoluteString,
                            duration: durationInSeconds,
                            roundTimestamps: []
                        )

                        try await self.db.collection("videos").document(videoId).setData(video.dictionary)
                        try await self.db.collection("fights").document(fight.id ?? "").updateData([
                            "videoId": videoId,
                            "videoURL": downloadURL.absoluteString
                        ])
                        completion(.success(video))

                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }

        // Gestion de l'échec de l'upload
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                completion(.failure(error))
            }
        }
    }
    func getVideo(by videoId: String, completion: @escaping (Result<Video, Error>) -> Void) {
        let docRef = db.collection("videos").document(videoId)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                guard let data = document.data() else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data found for video"])))
                    return
                }
                // Utilisation de l'initialiseur personnalisé pour créer l'objet Video
                if let video = Video(dictionary: data) {
                    completion(.success(video))
                } else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse video data"])))
                }
            } else {
                completion(.failure(error ?? NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Video not found"])))
            }
        }
    }

}
