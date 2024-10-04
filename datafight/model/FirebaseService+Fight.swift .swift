//
//  FirebaseService+Fight.swift .swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

// FirebaseService+Fight.swift

import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

extension FirebaseService {
    // MARK: - Fight Methods
    func updateFight(
        _ fight: Fight, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid, uid == fight.creatorUserId
        else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Utilisateur non autorisé"
                        ])))
            return
        }

        guard let fightId = fight.id else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "ID du combat manquant"
                        ])))
            return
        }

        var updateData: [String: Any] = [:]

        do {
            updateData = try fight.asDictionary()
        } catch {
            completion(.failure(error))
            return
        }

        // Si fightResult existe, ajoutez-le séparément au dictionnaire
        if let fightResult = fight.fightResult {
            updateData["fightResult"] = fightResult.dictionary
        }

        db.collection("fights").document(fightId).updateData(updateData) {
            error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func getFightsForEvent(
        eventId: String, completion: @escaping (Result<[Fight], Error>) -> Void
    ) {
        db.collection("fights")
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let fights =
                        querySnapshot?.documents.compactMap {
                            document -> Fight? in
                            try? document.data(as: Fight.self)
                        } ?? []
                    completion(.success(fights))
                }
            }
    }

    func saveFight(
        _ fight: Fight, completion: @escaping (Result<String, Error>) -> Void
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

        var fightToSave = fight
        fightToSave.creatorUserId = uid

        if let id = fightToSave.id {
            // Updating an existing fight
            do {
                try db.collection("fights").document(id).setData(
                    from: fightToSave
                ) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(id))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        } else {
            // Creating a new fight
            let newDocRef = db.collection("fights").document()
            fightToSave.id = newDocRef.documentID

            // Since @DocumentID ignores the id during encoding, we need to include it manually
            var fightData = try? Firestore.Encoder().encode(fightToSave)
            fightData?["id"] = fightToSave.id  // Include the id in the data

            newDocRef.setData(fightData ?? [:]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(newDocRef.documentID))
                }
            }
        }
    }

    func getFights(completion: @escaping (Result<[Fight], Error>) -> Void) {
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

        db.collection("fights")
            .whereField("creatorUserId", isEqualTo: uid)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let fights =
                        querySnapshot?.documents.compactMap {
                            document -> Fight? in
                            var fight = try? document.data(as: Fight.self)
                            fight?.id = document.documentID
                            return fight
                        } ?? []
                    completion(.success(fights))
                }
            }
    }

    func getFight(
        id: String, completion: @escaping (Result<Fight, Error>) -> Void
    ) {
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
                completion(
                    .failure(
                        NSError(
                            domain: "FirebaseService", code: 2,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Fight not found"
                            ])))
            }
        }
    }
    func deleteFight(
        _ fight: Fight, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let fightId = fight.id else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Fight ID is missing"
                        ])))
            return
        }

        let group = DispatchGroup()
        var deletionError: Error?

        // 1. Delete associated rounds
        group.enter()
        deleteRoundsForFight(fightId: fightId) { error in
            if let error = error {
                deletionError = error
            }
            group.leave()
        }

        // 2. Delete associated video document and storage file
        group.enter()
        deleteVideoForFight(fightId: fightId) { error in
            if let error = error {
                deletionError = error
            }
            group.leave()
        }

        // 3. Remove fight ID from events
        group.enter()
        removeReferenceFromEvents(fightId: fightId) { error in
            if let error = error {
                deletionError = error
            }
            group.leave()
        }

        // 4. Remove fight ID from fighters
        group.enter()
        removeReferenceFromFighters(fightId: fightId) { error in
            if let error = error {
                deletionError = error
            }
            group.leave()
        }

        // 5. Delete fight document
        group.enter()
        db.collection("fights").document(fightId).delete { error in
            if let error = error {
                deletionError = error
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if let error = deletionError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func deleteRoundsForFight(
        fightId: String, completion: @escaping (Error?) -> Void
    ) {
        db.collection("rounds").whereField("fightId", isEqualTo: fightId)
            .getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    completion(error)
                    return
                }

                let group = DispatchGroup()
                var deletionError: Error?

                for document in snapshot?.documents ?? [] {
                    group.enter()
                    self?.db.collection("rounds").document(document.documentID)
                        .delete { error in
                            if let error = error {
                                deletionError = error
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    completion(deletionError)
                }
            }
    }

    private func deleteVideoForFight(
        fightId: String, completion: @escaping (Error?) -> Void
    ) {
        db.collection("videos").whereField("fightId", isEqualTo: fightId)
            .getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    completion(error)
                    return
                }

                if let videoDocument = snapshot?.documents.first {
                    let videoId = videoDocument.documentID

                    // Delete video document
                    self?.db.collection("videos").document(videoId).delete {
                        error in
                        if let error = error {
                            completion(error)
                            return
                        }

                        // Delete video file from storage
                        let storageRef = Storage.storage().reference().child(
                            "videos/\(videoId).mp4")
                        storageRef.delete { error in
                            completion(error)
                        }
                    }
                } else {
                    completion(nil)
                }
            }
    }

    private func removeReferenceFromEvents(
        fightId: String, completion: @escaping (Error?) -> Void
    ) {
        db.collection("events").whereField("fightIds", arrayContains: fightId)
            .getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    completion(error)
                    return
                }

                let group = DispatchGroup()
                var updateError: Error?

                for document in snapshot?.documents ?? [] {
                    group.enter()
                    self?.db.collection("events").document(document.documentID)
                        .updateData([
                            "fightIds": FieldValue.arrayRemove([fightId])
                        ]) { error in
                            if let error = error {
                                updateError = error
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    completion(updateError)
                }
            }
    }

    private func removeReferenceFromFighters(
        fightId: String, completion: @escaping (Error?) -> Void
    ) {
        let group = DispatchGroup()
        var updateError: Error?

        // Remove from blue fighter
        group.enter()
        db.collection("fighters").whereField(
            "blueFightIds", arrayContains: fightId
        ).getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                updateError = error
                group.leave()
                return
            }

            if let fighterDocument = snapshot?.documents.first {
                self?.db.collection("fighters").document(
                    fighterDocument.documentID
                ).updateData([
                    "blueFightIds": FieldValue.arrayRemove([fightId])
                ]) { error in
                    if let error = error {
                        updateError = error
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }

        // Remove from red fighter
        group.enter()
        db.collection("fighters").whereField(
            "redFightIds", arrayContains: fightId
        ).getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                updateError = error
                group.leave()
                return
            }

            if let fighterDocument = snapshot?.documents.first {
                self?.db.collection("fighters").document(
                    fighterDocument.documentID
                ).updateData([
                    "redFightIds": FieldValue.arrayRemove([fightId])
                ]) { error in
                    if let error = error {
                        updateError = error
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(updateError)
        }
    }

}
extension FirebaseService {
    func saveFightAsync(_ fight: Fight) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            saveFight(fight) { result in
                switch result {
                case .success(let fightId):
                    continuation.resume(returning: fightId)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
