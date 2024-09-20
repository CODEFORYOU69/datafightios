//
//  FirebaseService+Round.swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

// FirebaseService+Round.swift

import Firebase
import FirebaseFirestore
import FirebaseAuth

extension FirebaseService {
    // MARK: - Round Methods

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
                               let decoder = JSONDecoder()
                               let jsonData = try JSONSerialization.data(withJSONObject: document.data() ?? [:], options: [])
                               var round = try decoder.decode(Round.self, from: jsonData)
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
                try db.collection("fights").document(fight.id!).collection("rounds").document(id).setData(from: round) { error in
                    if let error = error {
                        CoreDataManager.shared.saveRound(round, for: fight)  // Sauvegarde locale si erreur
                        completion(.failure(error))  // Gérer l'erreur Firebase
                    } else {
                        CoreDataManager.shared.saveRound(round, for: fight)  // Sauvegarde locale
                        completion(.success(()))  // Succès
                    }
                }
            } catch {
                CoreDataManager.shared.saveRound(round, for: fight)  // Sauvegarde locale si erreur de Firebase
                completion(.failure(error))  // Complétion avec l'erreur rencontrée
            }
        } else {
            CoreDataManager.shared.saveRound(round, for: fight)  // Sauvegarde locale si déconnecté
            completion(.success(()))  // Succès immédiat en mode hors-ligne
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
    func getAllRoundsForFight(_ fight: Fight, completion: @escaping (Result<[Round], Error>) -> Void) {
        print("Starting getAllRoundsForFight for fight ID: \(fight.id ?? "Unknown")")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            completion(.failure(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        print("User authenticated: \(uid)")
        
        guard let fightId = fight.id else {
            print("Error: Fight ID is missing")
            completion(.failure(NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fight ID is missing"])))
            return
        }
        
        print("Fight ID is valid: \(fightId)")
        
        // Vérification que l'utilisateur a bien accès aux rounds
        guard uid == fight.creatorUserId else {
            print("Error: User \(uid) does not have permission to access rounds for fight \(fightId)")
            completion(.failure(NSError(domain: "FirebaseService", code: 3, userInfo: [NSLocalizedDescriptionKey: "User does not have permission to access these rounds"])))
            return
        }
        
        print("User has permission to access rounds")

        // Interroger Firestore pour obtenir tous les rounds associés à ce fightId
        db.collection("rounds")
            .whereField("fightId", isEqualTo: fightId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Failed to fetch rounds for fight \(fightId): \(error.localizedDescription)")
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
                        print("Successfully decoded round: \(round.id ?? "unknown")")
                    } catch {
                        print("Failed to decode round from document \(document.documentID): \(error)")
                    }
                }
                
                if rounds.isEmpty {
                    print("Error: No valid rounds found for fight \(fightId)")
                    completion(.failure(NSError(domain: "FirebaseService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No valid rounds found for this fight"])))
                } else {
                    print("Successfully retrieved and decoded \(rounds.count) rounds for fight \(fightId)")
                    completion(.success(rounds))
                }
            }
    }


    func fetchUserRounds(completion: @escaping (Result<[Round], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        // Récupérer les combats de l'utilisateur
        getFights { result in
            switch result {
            case .success(let fights):
                let fightIds = fights.compactMap { $0.id }
                let chunkedFightIds = fightIds.chunked(into: 10) // Limite de 10 IDs par requête "in"

                var allRounds: [Round] = []
                let dispatchGroup = DispatchGroup()

                for ids in chunkedFightIds {
                    dispatchGroup.enter()
                    self.db.collection("rounds")
                        .whereField("fightId", in: ids)
                        .whereField("creatorUserId", isEqualTo: uid)  // Filtrer par utilisateur authentifié
                        .getDocuments { (snapshot, error) in
                            if let error = error {
                                print("Erreur lors de la récupération des rounds: \(error.localizedDescription)")
                            } else if let snapshot = snapshot {
                                let rounds = snapshot.documents.compactMap { document -> Round? in
                                    var round = try? document.data(as: Round.self)
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
                winner: winner,
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
    func getLastRoundEndTime(for fight: Fight, completion: @escaping (Result<TimeInterval, Error>) -> Void) {
        guard let fightId = fight.id else {
            completion(.failure(NSError(domain: "FightError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Fight ID is missing"])))
            return
        }
        
        Firestore.firestore().collection("videos").whereField("fightId", isEqualTo: fightId).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                completion(.failure(NSError(domain: "VideoError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No video found for this fight"])))
                return
            }
            
            let videoData = document.data()
            guard let video = Video(dictionary: videoData) else {
                completion(.failure(NSError(domain: "VideoError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse video data"])))
                return
            }
            
            if let lastRoundTimestamp = video.roundTimestamps.max(by: { $0.roundNumber < $1.roundNumber }) {
                let endTime = lastRoundTimestamp.end ?? lastRoundTimestamp.start
                completion(.success(endTime))
            } else {
                completion(.success(0)) // Pas de rounds enregistrés, commencer à 0
            }
        }
    }
}
// FirebaseService.swift

extension FirebaseService {
    // Fonction générique pour récupérer les valeurs distinctes
    func fetchDistinctValues(from collection: String, field: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        db.collection(collection)
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
