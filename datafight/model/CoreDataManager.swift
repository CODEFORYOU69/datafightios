    //
    //  CoreDataManager.swift
    //  datafight
    //
    //  Created by younes ouasmi on 23/08/2024.
    //

    import CoreData
    import Foundation




    class CoreDataManager {
        static let shared = CoreDataManager()
        

        private init() {}
        
        lazy var persistentContainer: NSPersistentContainer = {
            let container = NSPersistentContainer(name: "datafight")
            container.loadPersistentStores { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
            return container
        }()
        
        var context: NSManagedObjectContext {
            
            return persistentContainer.viewContext
        }
        
        
        
        func saveContext() {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
        
        // MARK: - Round Operations
        
        func saveRound(_ round: Round, for fight: Fight) {
            let roundEntity = RoundEntity(context: context)
            roundEntity.roundId = round.id
            roundEntity.fightId = fight.id
            roundEntity.roundNumber = Int16(round.roundNumber)
            roundEntity.chronoDuration = round.chronoDuration
            roundEntity.duration = round.duration
            roundEntity.roundTime = Int16(round.roundTime)
            roundEntity.blueFighterId = round.blueFighterId
            roundEntity.redFighterId = round.redFighterId
            roundEntity.victoryDecision = round.victoryDecision?.rawValue
            roundEntity.isSynced = round.isSynced
            
            // Handle actions
            let actionsSet = NSMutableSet()
            for action in round.actions {
                let actionEntity = ActionEntity(context: context)
                actionEntity.actionId = action.id
                actionEntity.fighterId = action.fighterId
                actionEntity.color = action.color.rawValue
                actionEntity.actionType = action.actionType.rawValue
                actionEntity.technique = action.technique?.rawValue
                actionEntity.limbUsed = action.limbUsed?.rawValue
                actionEntity.actionZone = action.actionZone?.rawValue
                actionEntity.timeStamp = action.timeStamp
                actionEntity.situation = action.situation?.rawValue
                actionEntity.gamjeonType = action.gamjeonType?.rawValue
                actionEntity.isActive = action.isActive ?? true
                actionEntity.chronoTimestamp = action.chronoTimestamp ?? 90
                actionsSet.add(actionEntity)
            }
            roundEntity.actions = actionsSet
            
            // Handle video replays
            let videoReplaysSet = NSMutableSet()
            for videoReplay in round.videoReplays {
                let videoReplayEntity = VideoReplayEntity(context: context)
                videoReplayEntity.replayId = videoReplay.id
                videoReplayEntity.requestedByFighterId = videoReplay.requestedByFighterId
                videoReplayEntity.requestedByColor = videoReplay.requestedByColor.rawValue
                videoReplayEntity.timeStamp = videoReplay.timeStamp
                videoReplayEntity.wasAccepted = videoReplay.wasAccepted
                videoReplayEntity.chronoTimestamp = videoReplay.chronoTimestamp
                videoReplaysSet.add(videoReplayEntity)
            }
            roundEntity.videoReplays = videoReplaysSet
            
            saveContext()
        }
        
        func getRound(id: String, for fight: Fight) -> Round? {
            let fetchRequest: NSFetchRequest<RoundEntity> = RoundEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "roundId == %@ AND fightId == %@", id, fight.id ?? "")
            
            do {
                let results = try context.fetch(fetchRequest)
                if let roundEntity = results.first {
                    return Round(from: roundEntity)
                }
            } catch {
                print("Error fetching round: \(error)")
            }
            
            return nil
        }
        
        func getRoundsForFight(_ fight: Fight) -> [Round] {
            let fetchRequest: NSFetchRequest<RoundEntity> = RoundEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "fightId == %@", fight.id ?? "")
            
            do {
                let results = try context.fetch(fetchRequest)
                return results.map { Round(from: $0) }
            } catch {
                print("Error fetching rounds: \(error)")
                return []
            }
        }
        
        func deleteRound(id: String, for fight: Fight) {
            let fetchRequest: NSFetchRequest<RoundEntity> = RoundEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "roundId == %@ AND fightId == %@", id, fight.id ?? "")
            
            do {
                let results = try context.fetch(fetchRequest)
                if let roundEntity = results.first {
                    context.delete(roundEntity)
                    saveContext()
                }
            } catch {
                print("Error deleting round: \(error)")
            }
        }
        
        func getUnsyncedRounds() -> [Round] {
              let fetchRequest: NSFetchRequest<RoundEntity> = RoundEntity.fetchRequest()
              fetchRequest.predicate = NSPredicate(format: "isSynced == false")
              
              do {
                  let results = try context.fetch(fetchRequest)
                  return results.compactMap { Round(from: $0) }
              } catch {
                  print("Error fetching unsynced rounds: \(error)")
                  return []
              }
          }
        func getFightForRound(_ round: Round) -> Fight? {
             let fetchRequest: NSFetchRequest<FightEntity> = FightEntity.fetchRequest()
             fetchRequest.predicate = NSPredicate(format: "id == %@", round.fightId)
             
             do {
                 let results = try context.fetch(fetchRequest)
                 if let fightEntity = results.first {
                     return Fight(from: fightEntity)
                 }
             } catch {
                 print("Error fetching fight for round: \(error)")
             }
             return nil
         }
        func markRoundAsSynced(id: String, for fight: Fight) {
            let fetchRequest: NSFetchRequest<RoundEntity> = RoundEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "roundId == %@ AND fightId == %@", id, fight.id ?? "")
            
            do {
                let results = try context.fetch(fetchRequest)
                if let roundEntity = results.first {
                    roundEntity.isSynced = true
                    saveContext()
                }
            } catch {
                print("Error marking round as synced: \(error)")
            }
        }
    }

    // MARK: - Conversion Helpers
    // MARK: - Fight Operations

    extension CoreDataManager {
        func saveFight(_ fight: Fight) {
            let fightEntity = FightEntity(context: context)
            fightEntity.id = fight.id
            fightEntity.creatorUserId = fight.creatorUserId
            fightEntity.eventId = fight.eventId
            fightEntity.fightNumber = Int16(fight.fightNumber)
            fightEntity.blueFighterId = fight.blueFighterId
            fightEntity.redFighterId = fight.redFighterId
            fightEntity.category = fight.category
            fightEntity.weightCategory = fight.weightCategory
            fightEntity.round = fight.round
            fightEntity.isOlympic = fight.isOlympic
            fightEntity.roundIds = fight.roundIds?.joined(separator: ",")

            if let fightResult = fight.fightResult {
                let fightResultEntity = FightResultEntity(context: context)
                fightResultEntity.winner = fightResult.winner
                fightResultEntity.method = fightResult.method
                fightResultEntity.blueScore = Int16(fightResult.totalScore.blue)
                fightResultEntity.redScore = Int16(fightResult.totalScore.red)
            }
            
            saveContext()
        }
    }
extension CoreDataManager {
    func deleteAllData() {
        // Obtenir toutes les entités du modèle de données gérées
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        
        for entityName in entityNames {
            // Créer une requête pour récupérer tous les objets de l'entité
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            
            // Créer une requête de suppression en lot
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                // Exécuter la requête de suppression
                try context.execute(deleteRequest)
                print("Tous les objets de \(entityName) ont été supprimés.")
            } catch let error as NSError {
                print("Erreur lors de la suppression des objets de \(entityName) : \(error.localizedDescription)")
            }
        }
        
        // Sauvegarder le contexte après avoir supprimé toutes les entités
        do {
            try context.save()
            print("Contexte sauvegardé après suppression.")
        } catch let error as NSError {
            print("Erreur lors de la sauvegarde du contexte après suppression : \(error.localizedDescription)")
        }
    }
}

