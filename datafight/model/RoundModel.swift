import Foundation
import FirebaseFirestore
import CoreData


struct Round: Codable, Identifiable {
    @DocumentID var id: String?  // Changé de UUID à String
    var fightId: String
    var roundNumber: Int
    var chronoDuration: TimeInterval  // Durée paramétrée du chrono
    var duration: TimeInterval  // Durée réelle du round
    var roundTime: Int
    var blueFighterId: String
    var redFighterId: String
    var actions: [Action]
    var videoReplays: [VideoReplay]
    var isSynced: Bool = false
    var victoryDecision: VictoryDecision?
    var roundWinner: String?
    var blueHits: Int = 0  // Nouvelle propriété
        var redHits: Int = 0

    
    enum CodingKeys: String, CodingKey {
        case id, fightId, roundNumber, chronoDuration, duration,roundTime, blueFighterId, redFighterId, actions, videoReplays, isSynced, victoryDecision, blueHits, redHits
    }

    var blueScore: Int {
        var score = actions.filter { $0.color == .blue && $0.actionType != .gamJeon }.reduce(0) { $0 + $1.points }
        score += actions.filter { $0.color == .red && $0.actionType == .gamJeon }.count // Add points for red's Gamjeon
        return score
    }

    var redScore: Int {
        var score = actions.filter { $0.color == .red && $0.actionType != .gamJeon }.reduce(0) { $0 + $1.points }
        score += actions.filter { $0.color == .blue && $0.actionType == .gamJeon }.count // Add points for blue's GamJeon
        return score
    }

    var blueGamJeon: Int {
        actions.filter { $0.color == .blue && $0.actionType == .gamJeon }.count
    }
    var redGamJeon: Int {
        actions.filter { $0.color == .red && $0.actionType == .gamJeon }.count
    }
    mutating func incrementHits(for color: FighterColor) {
           if color == .blue {
               blueHits += 1
           } else {
               redHits += 1
           }
       }
    mutating func determineRoundWinner() {
        if let decision = victoryDecision {
            switch decision {
            case .knockout, .technicalKnockout, .disqualification:
                // Victoire directe du round et du combat
                roundWinner = actions.last { $0.actionType == .kick || $0.actionType == .punch }?.fighterId
            case .punitiveDeclaration:
                // Victoire par 5 Gamjeons
                if blueGamJeon >= 5 {
                    roundWinner = redFighterId
                } else if redGamJeon >= 5 {
                    roundWinner = blueFighterId
                }
            case .pointGap:
                // Victoire par écart de 12 points
                if blueScore - redScore >= 12 {
                    roundWinner = blueFighterId
                } else if redScore - blueScore >= 12 {
                    roundWinner = redFighterId
                }
            case .finalScore:
                // Le combattant avec le plus de points gagne
                if blueScore > redScore {
                    roundWinner = blueFighterId
                } else if redScore > blueScore {
                    roundWinner = redFighterId
                } else {
                    determineWinnerBySuperiority()
                }
            case .withdrawal:
                // Match nul, déterminer par supériorité
                determineWinnerBySuperiority()
            default:
                // Pour les autres cas, ne rien faire
                break
            }
        } else {
            // Si pas de décision spécifique, déterminer par le score
            if blueScore > redScore {
                roundWinner = blueFighterId
            } else if redScore > blueScore {
                roundWinner = redFighterId
            } else {
                determineWinnerBySuperiority()
            }
        }
    }
    private mutating func determineWinnerBySuperiority() {
           let blueSpinningKicks = actions.filter { $0.color == .blue && [.spin360Body, .spin360Head].contains($0.technique) }.count
           let redSpinningKicks = actions.filter { $0.color == .red && [.spin360Body, .spin360Head].contains($0.technique) }.count
           
           if blueSpinningKicks > redSpinningKicks {
               roundWinner = blueFighterId
           } else if redSpinningKicks > blueSpinningKicks {
               roundWinner = redFighterId
           } else {
               // Comparer les techniques de plus haute valeur
               let blueHighValueTechniques = actions.filter { $0.color == .blue && $0.points >= 3 }.count
               let redHighValueTechniques = actions.filter { $0.color == .red && $0.points >= 3 }.count
               
               if blueHighValueTechniques > redHighValueTechniques {
                   roundWinner = blueFighterId
               } else if redHighValueTechniques > blueHighValueTechniques {
                   roundWinner = redFighterId
               } else {
                   // Comparer le nombre total de hits enregistrés
                   if blueHits > redHits {
                       roundWinner = blueFighterId
                   } else if redHits > blueHits {
                       roundWinner = redFighterId
                   } else {
                       // Si tout est égal, le vainqueur sera décidé par l'arbitre (Woo Se Kirok)
                       roundWinner = nil // L'arbitre devra décider manuellement
                   }
               }
           }
       }
}

struct Action: Codable, Identifiable {
    let id: String
    var fighterId: String
    var color: FighterColor
    var actionType: ActionType
    var technique: Technique?
    var limbUsed: Limb?
    var actionZone: Zone?
    var timeStamp: TimeInterval
    var situation: CombatSituation?
    var gamjeonType: GamjeonType?
    var guardPosition: GuardPosition?  // Nouvel attribut
    var blueFighterId: String?   // Ajouté
    var redFighterId: String?    // Ajouté
    var videoTimestamp: Double
    var isActive: Bool = true  // Nouvel attribut




    var points: Int {
        switch actionType {
        case .kick, .punch:
            return technique?.points ?? 0
        case .gamJeon:
            return -1  // Add 1 point to the opponent
        case .videoReplay:
            return 0
        }
    }
}

enum ActionType: String, Codable, CaseIterable {
    case kick
    case punch
    case gamJeon
    case videoReplay
}

enum GuardPosition: String, Codable, CaseIterable {
    case open = "Open"
    case closed = "Closed"
}

enum FighterColor: String, Codable, CaseIterable {
    case blue
    case red
}

enum Technique: String, Codable, CaseIterable {
    case cut = "Cut"
    case cutTwoSteps = "Cut 2 Steps"
    case cutThreeSteps = "Cut 3 Steps"
    case bandal = "Bandal"
    case doubleBandal = "Double Bandal"
    case apalTolyo = "Apal Tolyo"
    case tolyo = "Tolyo"
    case koroTolyo = "Koro Tolyo"
    case antal = "Antal"
    case nelyoFrontLeg = "Nelyo Front Leg"
    case nelyo = "Nelyo"
    case duitTchagui = "Duit Tchagui"
    case mondolyoBody = "Mondolyo Body"
    case mondolyoHead = "Mondolyo Head"
    case spin360Body = "360 Body"
    case spin360Head = "360 Head"
    case duitTchaguiHead = " duitTchagui Head"
    case koroNelyo = "Koro Nelyo"
    case fakeKoroNelyoBackNelyo = "Fake Koro Nelyo + Back Nelyo"
    case punch = "Punch"

    var points: Int {
        switch self {
        case .cut, .cutTwoSteps, .cutThreeSteps, .bandal, .doubleBandal:
            return 2
        case .apalTolyo, .tolyo, .koroTolyo, .antal, .nelyoFrontLeg, .nelyo, .koroNelyo, .fakeKoroNelyoBackNelyo:
            return 3
        case .duitTchagui, .spin360Body:
            return 4
        case .mondolyoHead, .spin360Head, .duitTchaguiHead:
            return 5
        case .mondolyoBody:
            return 4
        case .punch:
            return 1
        }
    }
}

enum Limb: String, Codable, CaseIterable {
    case frontLegRight = "Front Leg Right"
    case backLegRight = "Back Leg Right"
    case frontArmRight = "Front Arm Right"
    case backArmRight = "Back Arm Right"
    case frontLegLeft = "Front Leg Left"
    case backLegLeft = "Back Leg Left"
    case frontArmLeft = "Front Arm Left"
    case backArmLeft = "Back Arm Left"
}

enum Zone: String, Codable, CaseIterable {
    case Z1, Z2, Z3
}

enum CombatSituation: String, Codable, CaseIterable {
    case attack = "Attack"
    case defense = "Defense"
    case clinch = "Clinch"
}

enum GamjeonType: String, Codable, CaseIterable {
    case crossingBoundaryLine = "Crossing Boundary Line"
    case fallingDown = "Falling Down"
    case avoidingOrDelayingMatch = "Avoiding or Delaying Match"
    case grabbing = "Grabbing"
    case pushing = "Pushing"
    case attackingWithKnee = "Attacking with Knee"
    case attackingFallenOpponent = "Attacking Fallen Opponent"
    case misconductOfContestantOrCoach = "Misconduct of Contestant or Coach"
    case liftingLeg = "Lifting Leg to Block"
    case attackingBelowWaist = "Attacking Below Waist"
    case invalidAttack = "Invalid Attack"
    case excessiveContact = "Excessive Contact"
}

enum VictoryDecision: String, Codable, CaseIterable {
    case pointGap = "PTG"
    case superiorityDecision = "SUP"
    case punitiveDeclaration = "PUN"
    case referee = "RSC"
    case knockout = "KO"
    case technicalKnockout = "TKO"
    case withdrawal = "WDR"
    case disqualification = "DSQ"
    case finalScore = "PTF"
}

struct VideoReplay: Codable, Identifiable {
    let id: String
    var requestedByFighterId: String
    var requestedByColor: FighterColor
    var timeStamp: TimeInterval
    var wasAccepted: Bool
}

// MARK: - Core Data Helper
// MARK: - Core Data Helper

extension Round {
    func toCoreDataObject(in context: NSManagedObjectContext) -> RoundEntity {
        let roundEntity = RoundEntity(context: context)
        roundEntity.roundId = self.id
        roundEntity.fightId = self.fightId
        roundEntity.roundNumber = Int16(self.roundNumber)
        roundEntity.chronoDuration = self.chronoDuration
        roundEntity.duration = self.duration
        roundEntity.blueFighterId = self.blueFighterId
        roundEntity.redFighterId = self.redFighterId
        roundEntity.victoryDecision = self.victoryDecision?.rawValue
        roundEntity.isSynced = self.isSynced
        roundEntity.roundWinner = self.roundWinner
        roundEntity.blueScore = Int16(self.blueScore)
        roundEntity.redScore = Int16(self.redScore)
        roundEntity.blueHits = Int16(self.blueHits)
        roundEntity.redHits = Int16(self.redHits)
        roundEntity.roundTime = Int16(self.roundTime)

        

        
        // Handle actions
        let actionsSet = NSMutableSet()
        for action in self.actions {
            let actionEntity = action.toCoreDataObject(in: context)
            actionsSet.add(actionEntity)
        }
        roundEntity.actions = actionsSet
        
        // Handle video replays
        let videoReplaysSet = NSMutableSet()
        for videoReplay in self.videoReplays {
            let videoReplayEntity = videoReplay.toCoreDataObject(in: context)
            videoReplaysSet.add(videoReplayEntity)
        }
        roundEntity.videoReplays = videoReplaysSet
        
        return roundEntity
    }
    
    init(from entity: RoundEntity) {
        self.id = entity.roundId ?? String()
        self.fightId = entity.fightId ?? ""
        self.roundNumber = Int(entity.roundNumber)
        self.roundTime = Int(entity.roundTime)
        self.chronoDuration = entity.chronoDuration
        self.duration = entity.duration
        self.blueFighterId = entity.blueFighterId ?? ""
        self.redFighterId = entity.redFighterId ?? ""
        self.victoryDecision = VictoryDecision(rawValue: entity.victoryDecision ?? "")
        self.isSynced = entity.isSynced
        self.roundWinner = entity.roundWinner
        self.blueHits = Int(entity.blueHits)
                self.redHits = Int(entity.redHits)
     

        
        self.actions = (entity.actions?.allObjects as? [ActionEntity])?.compactMap { Action(from: $0) } ?? []
        self.videoReplays = (entity.videoReplays?.allObjects as? [VideoReplayEntity])?.compactMap { VideoReplay(from: $0) } ?? []
    }
}

extension Action {
    func toCoreDataObject(in context: NSManagedObjectContext) -> ActionEntity {
        let actionEntity = ActionEntity(context: context)
        actionEntity.actionId = self.id
        actionEntity.fighterId = self.fighterId
        actionEntity.color = self.color.rawValue
        actionEntity.actionType = self.actionType.rawValue
        actionEntity.technique = self.technique?.rawValue
        actionEntity.limbUsed = self.limbUsed?.rawValue
        actionEntity.actionZone = self.actionZone?.rawValue
        actionEntity.timeStamp = self.timeStamp
        actionEntity.situation = self.situation?.rawValue
        actionEntity.gamjeonType = self.gamjeonType?.rawValue
        actionEntity.guardPosition = self.guardPosition?.rawValue
        actionEntity.videoTimestamp = self.videoTimestamp
        actionEntity.isActive = self.isActive
        return actionEntity
    }
    
    init(from entity: ActionEntity) {
            self.id = entity.actionId ?? UUID().uuidString
            self.fighterId = entity.fighterId ?? ""
            self.color = FighterColor(rawValue: entity.color ?? "") ?? .blue
        self.actionType = ActionType(rawValue: entity.actionType ?? "") ?? .kick
            self.technique = Technique(rawValue: entity.technique ?? "")
            self.limbUsed = Limb(rawValue: entity.limbUsed ?? "")
            self.actionZone = Zone(rawValue: entity.actionZone ?? "")
            self.timeStamp = entity.timeStamp
            self.situation = CombatSituation(rawValue: entity.situation ?? "") ?? .attack
            self.gamjeonType = GamjeonType(rawValue: entity.gamjeonType ?? "")
            self.guardPosition = GuardPosition(rawValue: entity.guardPosition ?? "")
            self.videoTimestamp = entity.videoTimestamp
            self.isActive = entity.isActive
        }
}

extension VideoReplay {
    func toCoreDataObject(in context: NSManagedObjectContext) -> VideoReplayEntity {
        let videoReplayEntity = VideoReplayEntity(context: context)
        videoReplayEntity.replayId = self.id
        videoReplayEntity.requestedByFighterId = self.requestedByFighterId
        videoReplayEntity.requestedByColor = self.requestedByColor.rawValue
        videoReplayEntity.timeStamp = self.timeStamp
        videoReplayEntity.wasAccepted = self.wasAccepted
        return videoReplayEntity
    }
    
    init(from entity: VideoReplayEntity) {
        self.id = entity.replayId ?? String()
        self.requestedByFighterId = entity.requestedByFighterId ?? ""
        self.requestedByColor = FighterColor(rawValue: entity.requestedByColor ?? "") ?? .blue
        self.timeStamp = entity.timeStamp
        self.wasAccepted = entity.wasAccepted
    }
}
extension Action {
    var dictionary: [String: Any] {
        return [
            "id": id,
            "fighterId": fighterId,
            "color": color.rawValue,
            "actionType": actionType.rawValue,
            "technique": technique?.rawValue as Any,
            "limbUsed": limbUsed?.rawValue as Any,
            "actionZone": actionZone?.rawValue as Any,
            "timeStamp": timeStamp,
            "situation": situation?.rawValue as Any,
            "gamjeonType": gamjeonType?.rawValue as Any,
            "guardPosition": guardPosition?.rawValue as Any,
            "videoTimestamp": videoTimestamp
        ]
    }
}

extension Round {
    var dictionary: [String: Any] {
            var dict = [
                "id": id as Any,
                "fightId": fightId,
                "roundNumber": roundNumber,
                "chronoDuration": chronoDuration,
                "duration": duration,
                "roundTime": roundTime,
                "blueFighterId": blueFighterId,
                "redFighterId": redFighterId,
                "actions": actions.map { $0.dictionary },
                "videoReplays": videoReplays.map { $0.dictionary },
                "isSynced": isSynced,
                "blueHits": blueHits,
                "redHits": redHits
            ]
            if let victoryDecision = victoryDecision {
                dict["victoryDecision"] = victoryDecision.rawValue
            }
            if let roundWinner = roundWinner {
                dict["roundWinner"] = roundWinner
            }
            return dict
        }
}
extension VideoReplay {
    var dictionary: [String: Any] {
        return [
            "id": id,
            "requestedByFighterId": requestedByFighterId,
            "requestedByColor": requestedByColor.rawValue,
            "timeStamp": timeStamp,
            "wasAccepted": wasAccepted
        ]
    }
}
extension Round {
    func determineWinner(isEndedByTime: Bool) -> (winner: FighterColor?, decision: VictoryDecision) {
            // Vérifier d'abord les cas de victoire directe
            if let directWinner = checkDirectVictory() {
                return directWinner
            }

            // Vérifier l'écart de points
            if abs(blueScore - redScore) >= 12 {
                return (blueScore > redScore ? .blue : .red, .pointGap)
            }

            // Vérifier les gamjeons
            if blueGamJeon >= 5 {
                return (.red, .punitiveDeclaration)
            } else if redGamJeon >= 5 {
                return (.blue, .punitiveDeclaration)
            }

            // Si le round s'est terminé par expiration du temps, procéder à la détermination du vainqueur
            if isEndedByTime {
                if blueScore > redScore {
                    return (.blue, .finalScore)
                } else if redScore > blueScore {
                    return (.red, .finalScore)
                } else {
                    // En cas d'égalité, passer à la détermination par supériorité
                    return determineBySuperiorityOrReferee()
                }
            } else {
                // Si le round ne s'est pas terminé par expiration du temps,
                // il faut déterminer la raison (KO, disqualification, etc.)
                // Cela pourrait être fait en examinant la dernière action ou en demandant à l'utilisateur
                return determineNonTimeEndWinner()
            }
        }

        private func determineNonTimeEndWinner() -> (winner: FighterColor?, decision: VictoryDecision) {
            // Logique pour déterminer le vainqueur quand le round ne se termine pas par expiration du temps
            // Par exemple, examiner la dernière action pour voir s'il y a eu un KO
            if let lastAction = actions.last,
               (lastAction.actionType == .kick || lastAction.actionType == .punch),
               let technique = lastAction.technique,
               technique == .mondolyoHead || technique == .spin360Head || technique == .duitTchaguiHead {
                return (lastAction.color, .knockout)
            }
            
            // Si aucune condition spéciale n'est remplie, on pourrait retourner nil ou demander une décision de l'arbitre
            return (nil, .referee)
        }

    private func checkDirectVictory() -> (winner: FighterColor, decision: VictoryDecision)? {
        if let lastAction = actions.last,
           (lastAction.actionType == .kick || lastAction.actionType == .punch),
           let technique = lastAction.technique,
           technique == .mondolyoHead || technique == .spin360Head || technique == .duitTchaguiHead {
            return (lastAction.color, .knockout)
        }
        return nil
    }

    private func determineBySuperiorityOrReferee() -> (winner: FighterColor?, decision: VictoryDecision) {
        let pointValues = [5, 4, 3, 2]
        
        for points in pointValues {
            let blueCount = actions.filter { $0.color == .blue && $0.points == points }.count
            let redCount = actions.filter { $0.color == .red && $0.points == points }.count
            
            if blueCount != redCount {
                return (blueCount > redCount ? .blue : .red, .superiorityDecision)
            }
        }

        // Comparer le nombre de gamjeons (moins est mieux)
        if blueGamJeon != redGamJeon {
            return (blueGamJeon < redGamJeon ? .blue : .red, .superiorityDecision)
        }

        // Comparer le nombre de hits
        if blueHits != redHits {
            return (blueHits > redHits ? .blue : .red, .superiorityDecision)
        }

        // Si tout est égal, la décision revient aux arbitres
        return (nil, .referee)
    }
}
