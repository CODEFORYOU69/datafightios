//
//  FirebaseService+User.swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

// FirebaseService+User.swift

import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit
import FirebaseAuth

extension FirebaseService {
    // MARK: - User Methods

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

            db.collection("users").document(uid).setData(userData, merge: true) { error in
                if let error = error {
                    print("Failed to update Firestore: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("User profile successfully updated in Firestore")
                    completion(.success(()))
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
