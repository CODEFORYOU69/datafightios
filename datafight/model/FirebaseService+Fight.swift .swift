//
//  FirebaseService+Fight.swift .swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

// FirebaseService+Fight.swift

import Firebase
import FirebaseFirestore
import FirebaseAuth

extension FirebaseService {
    // MARK: - Fight Methods
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

    func saveFight(_ fight: Fight, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        var fightToSave = fight
        fightToSave.creatorUserId = uid

        if let id = fightToSave.id {
            do {
                try db.collection("fights").document(id).setData(from: fightToSave) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(id))
                    }
                }
            } catch {
                completion(.failure(error)) // Gérer l'erreur si `setData(from:)` échoue
            }
        } else {
            let newDocRef = db.collection("fights").document()
            fightToSave.id = newDocRef.documentID
            do {
                try newDocRef.setData(from: fightToSave) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(newDocRef.documentID))
                    }
                }
            } catch {
                completion(.failure(error)) // Gérer l'erreur si `setData(from:)` échoue
            }
        }
    }


    func getFights(completion: @escaping (Result<[Fight], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        db.collection("fights")
            .whereField("creatorUserId", isEqualTo: uid)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let fights = querySnapshot?.documents.compactMap { document -> Fight? in
                        var fight = try? document.data(as: Fight.self)
                        fight?.id = document.documentID
                        return fight
                    } ?? []
                    completion(.success(fights))
                }
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

    // Fonction pour le chatbot: Récupérer les valeurs distinctes des attributs des combats
    func fetchDistinctFightValues(for field: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        db.collection("fights")
            .whereField("creatorUserId", isEqualTo: uid)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let snapshot = snapshot {
                    var valuesSet = Set<String>()
                    for document in snapshot.documents {
                        if let value = document.data()[field] as? String {
                            valuesSet.insert(value)
                        }
                    }
                    completion(.success(Array(valuesSet)))
                } else {
                    completion(.success([]))
                }
            }
    }
}
