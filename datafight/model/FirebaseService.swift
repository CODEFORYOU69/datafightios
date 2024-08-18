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
                    try? document.data(as: Fighter.self)
                } ?? []
                completion(.success(fighters))
            }
        }
    }
    
    func getFighter(id: String, completion: @escaping (Result<Fighter, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        db.collection("fighters").document(id).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                do {
                    let fighter = try document.data(as: Fighter.self)
                    if fighter.creatorUserId == uid {
                        completion(.success(fighter))
                    } else {
                        completion(.failure(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "You don't have permission to access this fighter"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
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

    func saveEvent(_ event: Event, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            if let id = event.id {
                try db.collection("events").document(id).setData(from: event)
            } else {
                _ = try db.collection("events").addDocument(from: event)
            }
            completion(.success(()))
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
                    try? document.data(as: Event.self)
                } ?? []
                completion(.success(events))
            }
        }
    }
}
