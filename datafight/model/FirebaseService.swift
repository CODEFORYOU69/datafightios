import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
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
