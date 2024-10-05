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
    func getFighterCompleteStats(fighterId: String, completion: @escaping (Result<FighterCompleteStats, Error>) -> Void) {
           getFights { result in
               switch result {
               case .success(let allFights):
                   let fighterFights = allFights.filter { $0.blueFighterId == fighterId || $0.redFighterId == fighterId }
                   
                   let totalFights = fighterFights.count
                   let totalWins = fighterFights.filter { $0.fightResult?.winner == fighterId }.count
                   let winPercentage = totalFights > 0 ? Double(totalWins) / Double(totalFights) * 100 : 0
                   
                   let fightsByEvent = Dictionary(grouping: fighterFights, by: { $0.eventId })
                   let totalCompetitions = fightsByEvent.keys.count
                   
                   var goldMedals = 0
                   var silverMedals = 0
                   var bronzeMedals = 0
                   var medalCompetitions: [MedalCompetition] = []
                   
                   let group = DispatchGroup()
                   
                   for (eventId, fights) in fightsByEvent {
                       group.enter()
                       self.processMedalForEvent(eventId: eventId, fights: fights, fighterId: fighterId) { medalResult in
                           switch medalResult {
                           case .success(let medalInfo):
                               if let medal = medalInfo.medal {
                                   switch medal {
                                   case .gold: goldMedals += 1
                                   case .silver: silverMedals += 1
                                   case .bronze: bronzeMedals += 1
                                   }
                                   medalCompetitions.append(MedalCompetition(competitionName: medalInfo.eventName, medalColor: medal, fightCount: fights.count))
                               }
                           case .failure(let error):
                               print("Error processing medal for event: \(error.localizedDescription)")
                           }
                           group.leave()
                       }
                   }
                   
                   group.notify(queue: .main) {
                       let stats = FighterCompleteStats(
                           totalCompetitions: totalCompetitions,
                           totalFights: totalFights,
                           totalWins: totalWins,
                           winPercentage: winPercentage,
                           goldMedals: goldMedals,
                           silverMedals: silverMedals,
                           bronzeMedals: bronzeMedals,
                           medalCompetitions: medalCompetitions
                       )
                       completion(.success(stats))
                   }
                   
               case .failure(let error):
                   completion(.failure(error))
               }
           }
       }
       
       private func processMedalForEvent(eventId: String, fights: [Fight], fighterId: String, completion: @escaping (Result<(medal: MedalColor?, eventName: String), Error>) -> Void) {
           let finalFight = fights.first { $0.round?.lowercased() == "final" }
           let semiFinalFight = fights.first { $0.round?.lowercased() == "semi final" }
           let thirdPlaceFight = fights.first { $0.round?.lowercased() == "third place" }
           
           var medal: MedalColor?
           
           if let final = finalFight {
               medal = final.fightResult?.winner == fighterId ? .gold : .silver
           } else if semiFinalFight != nil {
               medal = .bronze
           } else if let thirdPlace = thirdPlaceFight, thirdPlace.fightResult?.winner == fighterId {
               medal = .bronze
           }
           
           getEvent(id: eventId) { eventResult in
               switch eventResult {
               case .success(let event):
                   completion(.success((medal: medal, eventName: event.eventName)))
               case .failure(let error):
                   completion(.failure(error))
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
    func getFighterCompleteStatsAsync(fighterId: String) async throws -> FighterCompleteStats {
           return try await withCheckedThrowingContinuation { continuation in
               getFighterCompleteStats(fighterId: fighterId) { result in
                   switch result {
                   case .success(let stats):
                       continuation.resume(returning: stats)
                   case .failure(let error):
                       continuation.resume(throwing: error)
                   }
               }
           }
       }
}
struct FighterCompleteStats {
    let totalCompetitions: Int
    let totalFights: Int
    let totalWins: Int
    let winPercentage: Double
    let goldMedals: Int
    let silverMedals: Int
    let bronzeMedals: Int
    let medalCompetitions: [MedalCompetition]
}
enum MedalColor {
    case gold, silver, bronze
}

struct MedalCompetition {
    let competitionName: String
    let medalColor: MedalColor
    let fightCount: Int
}
