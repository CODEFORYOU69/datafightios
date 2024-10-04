//
//  FirebaseService+Fighter.swift .swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

extension FirebaseService {
    // MARK: - Fighter Methods

    func saveFighter(
        _ fighter: Fighter,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not authenticated"
                        ])))
            return
        }

        var fighterData = fighter
        fighterData.creatorUserId = uid  // Ensure that the user ID is set

        let newDocRef = db.collection("fighters").document()  // Create a new document reference
        fighterData.id = newDocRef.documentID  // Set the fighter's ID

        do {
            try newDocRef.setData(from: fighterData) { error in
                if let error = error {
                    completion(.failure(error))  // Return the error in the completion handler
                } else {
                    completion(.success(newDocRef.documentID))  // Return the fighter ID upon success
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func getFighters(completion: @escaping (Result<[Fighter], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not authenticated"
                        ])))
            return
        }

        db.collection("fighters")
            .whereField("creatorUserId", isEqualTo: uid)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let fighters =
                        querySnapshot?.documents.compactMap {
                            document -> Fighter? in
                            var fighter = try? document.data(as: Fighter.self)
                            fighter?.id = document.documentID  // Assigner l'ID du document à l'objet Fighter
                            return fighter
                        } ?? []
                    completion(.success(fighters))
                }
            }
    }

    func getFighter(
        id: String, completion: @escaping (Result<Fighter, Error>) -> Void
    ) {
        db.collection("fighters").document(id).getDocument {
            (document, error) in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                do {
                    var fighter = try document.data(as: Fighter.self)
                    fighter.id = document.documentID
                    completion(.success(fighter))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(
                    .failure(
                        NSError(
                            domain: "FirebaseService", code: 2,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Fighter not found"
                            ])))
            }
        }
    }

    func uploadFighterImage(
        _ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Could not get image data"
                        ])))
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
                        completion(
                            .failure(
                                NSError(
                                    domain: "FirebaseService", code: 0,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "Unknown error occurred"
                                    ])))
                    }
                }
            }
        }
    }
    func updateFighterWithFight(
        fighterId: String, fightId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let fighterRef = db.collection("fighters").document(fighterId)
        fighterRef.updateData([
            "fightIds": FieldValue.arrayUnion([fightId])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

}
extension FirebaseService {

    func saveFighterAsync(_ fighter: Fighter) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            saveFighter(fighter) { result in
                switch result {
                case .success(let fighterId):
                    continuation.resume(returning: fighterId)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

}
