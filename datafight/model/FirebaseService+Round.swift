//
//  FirebaseService+Round.swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

// FirebaseService+Round.swift

import Firebase
import FirebaseAuth
import FirebaseFirestore

extension FirebaseService {
    // MARK: - Round Methods

    func saveRound(
        _ round: Round, for fight: Fight,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user")
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "No authenticated user"
                        ])))
            return
        }

        guard let fightId = fight.id else {
            print("Error: Fight ID is nil")
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Fight ID is nil"]
                    )))
            return
        }

        let roundRef = db.collection("rounds").document(
            round.id ?? UUID().uuidString)
        var roundToSave = round
        roundToSave.id = roundRef.documentID
        roundToSave.creatorUserId = uid
        roundToSave.fightId = fightId

        // Since @DocumentID ignores the id during encoding, include it manually
        var roundData = try? Firestore.Encoder().encode(roundToSave)
        roundData?["id"] = roundToSave.id

        let fightRef = db.collection("fights").document(fightId)
        let batch = db.batch()

        batch.setData(roundData ?? [:], forDocument: roundRef, merge: true)

        if round.id == nil {
            batch.updateData(
                ["roundIds": FieldValue.arrayUnion([roundRef.documentID])],
                forDocument: fightRef)
        }

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(roundRef.documentID))
            }
        }
    }
    func getRound(
        id: String, for fight: Fight,
        completion: @escaping (Result<Round, Error>) -> Void
    ) {
        print("GetRound called with ID: \(id)")
        print("Fight details:")
        print("  Fight ID: \(fight.id ?? "unknown")")
        print("  Creator User ID: \(fight.creatorUserId)")

        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user")
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "No authenticated user"
                        ])))
            return
        }

        print("Authenticated User ID: \(uid)")

        // Vérifier les permissions
        guard uid == fight.creatorUserId else {
            print("Error: User not authorized")
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not authorized"
                        ])))
            return
        }

        // Récupérer directement le document round depuis la collection "rounds"
        let roundRef = db.collection("rounds").document(id)
        print("Firestore reference path: \(roundRef.path)")

        // Récupérer le document depuis Firestore
        roundRef.getDocument { (document, error) in
            if let error = error {
                print(
                    "Error fetching round from Firestore: \(error.localizedDescription)"
                )
                completion(.failure(error))
            } else if let document = document, document.exists {
                print("Round document found in Firestore")
                do {
                    var round = try document.data(as: Round.self)
                    round.id = document.documentID
                    print("Successfully decoded round:")
                    print("  Round ID: \(round.id ?? "unknown")")
                    print("  Round Number: \(round.roundNumber)")
                    print("  Round Duration: \(round.duration)")

                    // Vérifier que le round appartient bien au combat
                    guard round.fightId == fight.id else {
                        print("Error: Round does not belong to this fight")
                        completion(
                            .failure(
                                NSError(
                                    domain: "FirebaseService", code: 4,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "Round does not belong to this fight"
                                    ])))
                        return
                    }

                    completion(.success(round))
                } catch {
                    print(
                        "Error decoding round data: \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                }
            } else {
                print("Round document not found in Firestore")
                completion(
                    .failure(
                        NSError(
                            domain: "FirebaseService", code: 3,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Round not found"
                            ])))
            }
        }
    }
    func getRoundsForFight(
        _ fight: Fight, completion: @escaping (Result<[Round], Error>) -> Void
    ) {
        print(
            "Starting getRoundsForFight for fight ID: \(fight.id ?? "unknown")")

        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not authenticated"
                        ])))
            return
        }

        print("User authenticated: \(uid)")

        guard let fightId = fight.id else {
            print("Error: Fight ID is missing")
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Fight ID is missing"
                        ])))
            return
        }

        print("Fight ID is valid: \(fightId)")

        // Vérification que l'utilisateur a bien accès aux rounds
        guard uid == fight.creatorUserId else {
            print(
                "Error: User \(uid) does not have permission to access rounds for fight \(fightId)"
            )
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "User does not have permission to access these rounds"
                        ])))
            return
        }

        print("User has permission to access rounds")

        // Récupérer le document du combat pour obtenir les IDs des rounds
        db.collection("fights").document(fightId).getDocument {
            (document, error) in
            if let error = error {
                print(
                    "Failed to fetch fight document: \(error.localizedDescription)"
                )
                completion(.failure(error))
                return
            }

            guard let document = document, document.exists else {
                print("Fight document not found")
                completion(
                    .failure(
                        NSError(
                            domain: "FirebaseService", code: 3,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Fight not found"
                            ])))
                return
            }

            guard let roundIds = document.data()?["roundIds"] as? [String],
                !roundIds.isEmpty
            else {
                print("No round IDs found for fight \(fightId)")
                completion(.success([]))
                return
            }

            print("Found \(roundIds.count) round IDs for fight \(fightId)")

            // Récupérer les documents des rounds
            let roundsRef = self.db.collection("rounds")
            roundsRef.whereField(FieldPath.documentID(), in: roundIds)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print(
                            "Failed to fetch rounds: \(error.localizedDescription)"
                        )
                        completion(.failure(error))
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("No round documents found")
                        completion(.success([]))
                        return
                    }

                    print("Found \(documents.count) round documents")

                    var rounds: [Round] = []
                    for document in documents {
                        do {
                            var round = try document.data(as: Round.self)
                            round.id = document.documentID
                            rounds.append(round)
                            print(
                                "Successfully decoded round: \(round.id ?? "unknown")"
                            )
                        } catch {
                            print(
                                "Failed to decode round from document \(document.documentID): \(error)"
                            )
                        }
                    }

                    if rounds.isEmpty {
                        print(
                            "Error: No valid rounds found for fight \(fightId)")
                        completion(
                            .failure(
                                NSError(
                                    domain: "FirebaseService", code: 4,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "No valid rounds found for this fight"
                                    ])))
                    } else {
                        let sortedRounds = rounds.sorted {
                            $0.roundNumber < $1.roundNumber
                        }
                        print(
                            "Successfully retrieved and decoded \(sortedRounds.count) rounds for fight \(fightId)"
                        )
                        completion(.success(sortedRounds))
                    }
                }
        }
    }

    func updateRound(
        _ round: Round, for fight: Fight,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid, uid == fight.creatorUserId
        else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not authorized"
                        ])))
            return
        }

        guard let roundId = round.id else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Round ID is missing"
                        ])))
            return
        }

        do {
            let roundData = try Firestore.Encoder().encode(round)
            db.collection("rounds").document(roundId).setData(
                roundData, merge: true
            ) { error in
                if let error = error {
                    print("Error updating round: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Round updated successfully")
                    completion(.success(()))
                }
            }
        } catch let error as NSError {
            print(
                "Error converting round to dictionary: \(error.localizedDescription), \(error.userInfo)"
            )
            completion(.failure(error))
        }
    }
    func deleteRound(
        id: String, for fight: Fight,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid, uid == fight.creatorUserId
        else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not authorized"
                        ])))
            return
        }

        guard let fightId = fight.id else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Fight ID is missing"
                        ])))
            return
        }

        db.collection("fights").document(fightId).collection("rounds").document(
            id
        ).delete { error in
            if let error = error {
                print("Error deleting round: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Round deleted successfully")
                completion(.success(()))
            }
        }
    }

    func getAllRoundsForFight(
        _ fight: Fight, completion: @escaping (Result<[Round], Error>) -> Void
    ) {
        print(
            "Starting getAllRoundsForFight for fight ID: \(fight.id ?? "Unknown")"
        )

        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not authenticated"
                        ])))
            return
        }

        print("User authenticated: \(uid)")

        guard let fightId = fight.id else {
            print("Error: Fight ID is missing")
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Fight ID is missing"
                        ])))
            return
        }

        print("Fight ID is valid: \(fightId)")

        // Vérification que l'utilisateur a bien accès aux rounds
        guard uid == fight.creatorUserId else {
            print(
                "Error: User \(uid) does not have permission to access rounds for fight \(fightId)"
            )
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 3,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "User does not have permission to access these rounds"
                        ])))
            return
        }

        print("User has permission to access rounds")

        db.collection("rounds")
            .whereField("fightId", isEqualTo: fightId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print(
                        "Failed to fetch rounds for fight \(fightId): \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("No documents found for fight \(fightId)")
                    completion(.success([]))
                    return
                }

                print("Found \(documents.count) documents for fight \(fightId)")

                // Mapper les documents Firestore en objets Round
                var rounds: [Round] = []
                for document in documents {
                    do {
                        let round = try document.data(as: Round.self)
                        rounds.append(round)
                        print(
                            "Successfully decoded round: \(round.id ?? "unknown")"
                        )
                    } catch {
                        print(
                            "Failed to decode round from document \(document.documentID): \(error)"
                        )
                    }
                }

                if rounds.isEmpty {
                    print("Error: No valid rounds found for fight \(fightId)")
                    completion(
                        .failure(
                            NSError(
                                domain: "FirebaseService", code: 4,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "No valid rounds found for this fight"
                                ])))
                } else {
                    print(
                        "Successfully retrieved and decoded \(rounds.count) rounds for fight \(fightId)"
                    )
                    completion(.success(rounds))
                }
            }
    }

    func fetchUserRounds(completion: @escaping (Result<[Round], Error>) -> Void)
    {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not authenticated"
                        ])))
            return
        }

        // Récupérer les combats de l'utilisateur
        getFights { result in
            switch result {
            case .success(let fights):
                let fightIds = fights.compactMap { $0.id }
                let chunkedFightIds = fightIds.chunked(into: 10)  // Limite de 10 IDs par requête "in"

                var allRounds: [Round] = []
                let dispatchGroup = DispatchGroup()

                for ids in chunkedFightIds {
                    dispatchGroup.enter()
                    self.db.collection("rounds")
                        .whereField("fightId", in: ids)
                        .whereField("creatorUserId", isEqualTo: uid)  // Filtrer par utilisateur authentifié
                        .getDocuments { (snapshot, error) in
                            if let error = error {
                                print(
                                    "Erreur lors de la récupération des rounds: \(error.localizedDescription)"
                                )
                            } else if let snapshot = snapshot {
                                let rounds = snapshot.documents.compactMap {
                                    document -> Round? in
                                    var round = try? document.data(
                                        as: Round.self)
                                    round?.id = document.documentID
                                    return round
                                }
                                allRounds.append(contentsOf: rounds)
                            }
                            dispatchGroup.leave()
                        }
                }

                dispatchGroup.notify(queue: .main) {
                    completion(.success(allRounds))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func saveAction(
        _ action: Action, for fight: Fight, videoTimestamp: TimeInterval,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let roundId = fight.roundIds?.last else {
            completion(
                .failure(
                    NSError(
                        domain: "FirebaseService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "No active round"]
                    )))
            return
        }

        // Ajouter le timestamp vidéo à l'action
        var actionWithTimestamp = action
        actionWithTimestamp.videoTimestamp = videoTimestamp

        let batch = db.batch()

        // Mise à jour du round avec la nouvelle action
        let roundRef = db.collection("rounds").document(roundId)
        batch.updateData(
            [
                "actions": FieldValue.arrayUnion([
                    actionWithTimestamp.dictionary
                ])
            ], forDocument: roundRef)

        // Mise à jour du document vidéo avec le nouveau timestamp d'action
        if let videoId = fight.videoId {
            let videoRef = db.collection("videos").document(videoId)
            batch.updateData(
                [
                    "actionTimestamps": FieldValue.arrayUnion([
                        [
                            "actionId": action.id,
                            "timestamp": videoTimestamp,
                        ]
                    ])
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
    func saveRoundAndUpdateFight(
        _ round: Round, for fight: Fight,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let batch = db.batch()
        guard let fightId = fight.id else {
            completion(
                .failure(
                    NSError(
                        domain: "FightError", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Fight ID is missing"
                        ])))
            return
        }

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

        let fightRef = db.collection("fights").document(fightId)

        // Update fight with new roundId if necessary
        if round.id == nil {
            batch.updateData(
                ["roundIds": FieldValue.arrayUnion([roundRef.documentID])],
                forDocument: fightRef)
        }

        // Check if the round result ends the fight
        if let victoryDecision = round.victoryDecision,
            ["KO", "TKO", "DSQ"].contains(victoryDecision.rawValue)
        {

            let winner =
                round.roundWinner == fight.blueFighterId ? "blue" : "red"
            let fightResult = FightResult(
                winner: winner,
                method: victoryDecision.rawValue,
                totalScore: (blue: round.blueScore, red: round.redScore)
            )

            // Update fight with the result
            batch.updateData(
                [
                    "fightResult": fightResult.dictionary,
                    "isCompleted": true,
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
    func getLastRoundEndTime(
        for fight: Fight,
        completion: @escaping (Result<TimeInterval, Error>) -> Void
    ) {
        guard let fightId = fight.id else {
            completion(
                .failure(
                    NSError(
                        domain: "FightError", code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Fight ID is missing"
                        ])))
            return
        }

        Firestore.firestore().collection("videos").whereField(
            "fightId", isEqualTo: fightId
        ).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let document = querySnapshot?.documents.first else {
                completion(
                    .failure(
                        NSError(
                            domain: "VideoError", code: 0,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "No video found for this fight"
                            ])))
                return
            }

            let videoData = document.data()
            guard let video = Video(dictionary: videoData) else {
                completion(
                    .failure(
                        NSError(
                            domain: "VideoError", code: 0,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Failed to parse video data"
                            ])))
                return
            }

            if let lastRoundTimestamp = video.roundTimestamps.max(by: {
                $0.roundNumber < $1.roundNumber
            }) {
                let endTime = lastRoundTimestamp.end ?? lastRoundTimestamp.start
                completion(.success(endTime))
            } else {
                completion(.success(0))  // Pas de rounds enregistrés, commencer à 0
            }
        }
    }
}
extension FirebaseService {
    func saveRoundAsync(_ round: Round, for fight: Fight) async throws -> String
    {
        try await withCheckedThrowingContinuation { continuation in
            saveRound(round, for: fight) { result in
                switch result {
                case .success(let roundId):
                    continuation.resume(returning: roundId)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
