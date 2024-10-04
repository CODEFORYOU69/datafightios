import FirebaseFirestore
import Foundation

struct Round: Codable, Identifiable {
    @DocumentID var id: String?  // Changé de UUID à String
    var fightId: String
    var creatorUserId: String
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
    var startTime: TimeInterval?  // Nouvelle propriété pour l'heure de début du round
    var endTime: TimeInterval?  // Nouvelle propriété pour l'heure de fi

    init(
        id: String? = nil,
        fightId: String,
        creatorUserId: String,
        roundNumber: Int,
        chronoDuration: TimeInterval,
        duration: TimeInterval,
        roundTime: Int,
        blueFighterId: String,
        redFighterId: String,
        actions: [Action] = [],
        videoReplays: [VideoReplay] = [],
        isSynced: Bool = false,
        victoryDecision: VictoryDecision? = nil,
        roundWinner: String? = nil,
        blueHits: Int = 0,
        redHits: Int = 0,
        startTime: TimeInterval? = nil,
        endTime: TimeInterval? = nil
    ) {
        self.id = id
        self.fightId = fightId
        self.creatorUserId = creatorUserId
        self.roundNumber = roundNumber
        self.chronoDuration = chronoDuration
        self.duration = duration
        self.roundTime = roundTime
        self.blueFighterId = blueFighterId
        self.redFighterId = redFighterId
        self.actions = actions
        self.videoReplays = videoReplays
        self.isSynced = isSynced
        self.victoryDecision = victoryDecision
        self.roundWinner = roundWinner
        self.blueHits = blueHits
        self.redHits = redHits
        self.startTime = startTime
        self.endTime = endTime
    }

    enum CodingKeys: String, CodingKey {
        case id, fightId, creatorUserId, roundNumber, chronoDuration, duration,
            roundTime, blueFighterId, redFighterId, actions, videoReplays,
            isSynced, victoryDecision, roundWinner, blueHits, redHits,
            startTime, endTime
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        fightId = try container.decode(String.self, forKey: .fightId)
        creatorUserId = try container.decode(
            String.self, forKey: .creatorUserId)
        roundNumber = try container.decode(Int.self, forKey: .roundNumber)
        chronoDuration = try container.decode(
            TimeInterval.self, forKey: .chronoDuration)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        roundTime = try container.decode(Int.self, forKey: .roundTime)
        blueFighterId = try container.decode(
            String.self, forKey: .blueFighterId)
        redFighterId = try container.decode(String.self, forKey: .redFighterId)
        actions = try container.decode([Action].self, forKey: .actions)
        videoReplays = try container.decode(
            [VideoReplay].self, forKey: .videoReplays)
        isSynced =
            try container.decodeIfPresent(Bool.self, forKey: .isSynced) ?? false
        victoryDecision = try container.decodeIfPresent(
            VictoryDecision.self, forKey: .victoryDecision)
        roundWinner = try container.decodeIfPresent(
            String.self, forKey: .roundWinner)
        blueHits =
            try container.decodeIfPresent(Int.self, forKey: .blueHits) ?? 0
        redHits = try container.decodeIfPresent(Int.self, forKey: .redHits) ?? 0
        startTime = try container.decodeIfPresent(
            TimeInterval.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(
            TimeInterval.self, forKey: .endTime)
    }

    var blueScore: Int {
        var score = actions.filter {
            $0.color == .blue && $0.actionType != .gamJeon
        }.reduce(0) { $0 + $1.points }
        score +=
            actions.filter { $0.color == .red && $0.actionType == .gamJeon }
            .count  // Add points for red's Gamjeon
        return score
    }

    var redScore: Int {
        var score = actions.filter {
            $0.color == .red && $0.actionType != .gamJeon
        }.reduce(0) { $0 + $1.points }
        score +=
            actions.filter { $0.color == .blue && $0.actionType == .gamJeon }
            .count  // Add points for blue's GamJeon
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
                roundWinner =
                    actions.last {
                        $0.actionType == .kick || $0.actionType == .punch
                    }?.fighterId
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
        let blueSpinningKicks = actions.filter {
            $0.color == .blue
                && [.spin360Body, .spin360Head].contains($0.technique)
        }.count
        let redSpinningKicks = actions.filter {
            $0.color == .red
                && [.spin360Body, .spin360Head].contains($0.technique)
        }.count

        if blueSpinningKicks > redSpinningKicks {
            roundWinner = blueFighterId
        } else if redSpinningKicks > blueSpinningKicks {
            roundWinner = redFighterId
        } else {
            // Comparer les techniques de plus haute valeur
            let blueHighValueTechniques = actions.filter {
                $0.color == .blue && $0.points >= 3
            }.count
            let redHighValueTechniques = actions.filter {
                $0.color == .red && $0.points >= 3
            }.count

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
                    roundWinner = nil  // L'arbitre devra décider manuellement
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
    var blueFighterId: String?  // Ajouté
    var redFighterId: String?  // Ajouté
    var videoTimestamp: Double
    var isActive: Bool? = true
    var chronoTimestamp: Double?  // Nouveau champ pour le chrono restant

    init(
        id: String = UUID().uuidString,
        fighterId: String,
        color: FighterColor,
        actionType: ActionType,
        technique: Technique? = nil,
        limbUsed: Limb? = nil,
        actionZone: Zone? = nil,
        timeStamp: TimeInterval,
        situation: CombatSituation? = nil,
        gamjeonType: GamjeonType? = nil,
        guardPosition: GuardPosition? = nil,
        blueFighterId: String? = nil,
        redFighterId: String? = nil,
        videoTimestamp: Double,
        isActive: Bool = true,
        chronoTimestamp: Double
    ) {
        self.id = id
        self.fighterId = fighterId
        self.color = color
        self.actionType = actionType
        self.technique = technique
        self.limbUsed = limbUsed
        self.actionZone = actionZone
        self.timeStamp = timeStamp
        self.situation = situation
        self.gamjeonType = gamjeonType
        self.guardPosition = guardPosition
        self.blueFighterId = blueFighterId
        self.redFighterId = redFighterId
        self.videoTimestamp = videoTimestamp
        self.isActive = isActive
        self.chronoTimestamp = chronoTimestamp
    }

    enum CodingKeys: String, CodingKey {
        case id, fighterId, color, actionType, technique, limbUsed, actionZone,
            timeStamp, situation, gamjeonType, blueFighterId, redFighterId,
            guardPosition, videoTimestamp, isActive, chronoTimestamp
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fighterId = try container.decode(String.self, forKey: .fighterId)
        color = try container.decode(FighterColor.self, forKey: .color)
        actionType = try container.decode(ActionType.self, forKey: .actionType)
        technique = try container.decodeIfPresent(
            Technique.self, forKey: .technique)
        limbUsed = try container.decodeIfPresent(Limb.self, forKey: .limbUsed)
        actionZone = try container.decodeIfPresent(
            Zone.self, forKey: .actionZone)
        timeStamp = try container.decode(TimeInterval.self, forKey: .timeStamp)
        situation = try container.decodeIfPresent(
            CombatSituation.self, forKey: .situation)
        gamjeonType = try container.decodeIfPresent(
            GamjeonType.self, forKey: .gamjeonType)
        guardPosition = try container.decodeIfPresent(
            GuardPosition.self, forKey: .guardPosition)
        blueFighterId = try container.decodeIfPresent(
            String.self, forKey: .blueFighterId)
        redFighterId = try container.decodeIfPresent(
            String.self, forKey: .redFighterId)
        videoTimestamp = try container.decode(
            Double.self, forKey: .videoTimestamp)
        isActive =
            try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        chronoTimestamp = try container.decodeIfPresent(
            Double.self, forKey: .chronoTimestamp)

    }

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
        case .apalTolyo, .tolyo, .koroTolyo, .antal, .nelyoFrontLeg, .nelyo,
            .koroNelyo, .fakeKoroNelyoBackNelyo:
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
    var chronoTimestamp: Double
    var wasAccepted: Bool
}

// MARK: - Core Data Helper
// MARK: - Core Data Helper

extension Action {
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "fighterId": fighterId,
            "color": color.rawValue,
            "actionType": actionType.rawValue,
            "timeStamp": timeStamp,
            "videoTimestamp": videoTimestamp,
            "isActive": isActive ?? true,
        ]

        if let technique = technique {
            dict["technique"] = technique.rawValue
        }
        if let limbUsed = limbUsed {
            dict["limbUsed"] = limbUsed.rawValue
        }
        if let actionZone = actionZone {
            dict["actionZone"] = actionZone.rawValue
        }
        if let situation = situation {
            dict["situation"] = situation.rawValue
        }
        if let gamjeonType = gamjeonType {
            dict["gamjeonType"] = gamjeonType.rawValue
        }
        if let guardPosition = guardPosition {
            dict["guardPosition"] = guardPosition.rawValue
        }
        if let blueFighterId = blueFighterId {
            dict["blueFighterId"] = blueFighterId
        }
        if let redFighterId = redFighterId {
            dict["redFighterId"] = redFighterId
        }
        if let chronoTimestamp = chronoTimestamp {
            dict["chronoTimestamp"] = chronoTimestamp
        }

        return dict
    }
}

extension Round {
    var dictionary: [String: Any] {
        var dict = [
            "id": id as Any,
            "fightId": fightId,
            "creatorUserId": creatorUserId,
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
            "redHits": redHits,
        ]
        if let startTime = startTime {
            dict["startTime"] = startTime
        }
        if let endTime = endTime {
            dict["endTime"] = endTime
        }
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
            "wasAccepted": wasAccepted,
            "chronoTimestamp": chronoTimestamp,
        ]
    }
}

protocol RoundWinnerDeterminer: AnyObject {
    func determineNonTimeEndWinner() -> (
        winner: FighterColor?, decision: VictoryDecision
    )
}

extension Round {
    mutating func determineWinner(
        isEndedByTime: Bool, determiner: RoundWinnerDeterminer?
    ) -> (winner: FighterColor?, decision: VictoryDecision) {
        print("Determining winner - Round ended by time: \(isEndedByTime)")

        // Check for point gap victory
        if abs(blueScore - redScore) >= 12 {
            let winner =
                blueScore > redScore ? FighterColor.blue : FighterColor.red
            print(
                "Point gap victory - Winner: \(winner), Blue Score: \(blueScore), Red Score: \(redScore)"
            )
            return (winner, .pointGap)
        }

        // Check for punitive declaration
        if blueGamJeon >= 5 {
            print(
                "Red wins by punitive declaration - Blue Gamjeons: \(blueGamJeon)"
            )
            return (.red, .punitiveDeclaration)
        } else if redGamJeon >= 5 {
            print(
                "Blue wins by punitive declaration - Red Gamjeons: \(redGamJeon)"
            )
            return (.blue, .punitiveDeclaration)
        }

        // Determine winner based on time expiration or other factors
        if isEndedByTime {
            return determineWinnerByScore()
        } else {
            // If the round did not end by time expiration, ask the determiner for a decision
            print("Round did not end by time, asking determiner for decision")
            let result =
                determiner?.determineNonTimeEndWinner() ?? (nil, .referee)
            print(
                "Determiner decision: Winner - \(result.winner?.rawValue ?? "None"), Decision - \(result.decision)"
            )
            return result
        }
    }

    private func determineWinnerByScore() -> (
        winner: FighterColor?, decision: VictoryDecision
    ) {
        if blueScore > redScore {
            print(
                "Blue wins by final score - Blue: \(blueScore), Red: \(redScore)"
            )
            return (.blue, .finalScore)
        } else if redScore > blueScore {
            print(
                "Red wins by final score - Red: \(redScore), Blue: \(blueScore)"
            )
            return (.red, .finalScore)
        } else {
            print("Scores are tied, determining by superiority")
            let superiorityResult = determineBySuperiorityOrReferee()

            switch superiorityResult {
            case .winner(let color):
                return (color, .superiorityDecision)
            case .referee:
                return (nil, .referee)
            }
        }

        enum SuperiorityResult {
            case winner(FighterColor)
            case referee
        }

        func determineBySuperiorityOrReferee() -> SuperiorityResult {
            print("Determining winner by superiority")
            let pointValues = [5, 4, 3, 2]

            for points in pointValues {
                let blueCount = actions.filter {
                    $0.color == .blue && $0.points == points
                }.count
                let redCount = actions.filter {
                    $0.color == .red && $0.points == points
                }.count

                print(
                    "Checking \(points)-point techniques - Blue: \(blueCount), Red: \(redCount)"
                )

                if blueCount != redCount {
                    let winner =
                        blueCount > redCount
                        ? FighterColor.blue : FighterColor.red
                    print(
                        "Superiority decided by \(points)-point techniques - Winner: \(winner)"
                    )
                    return .winner(winner)
                }
            }

            // Comparer le nombre de gamjeons (moins est mieux)
            if blueGamJeon != redGamJeon {
                let winner =
                    blueGamJeon < redGamJeon
                    ? FighterColor.blue : FighterColor.red
                print(
                    "Superiority decided by gamjeons - Winner: \(winner), Blue Gamjeons: \(blueGamJeon), Red Gamjeons: \(redGamJeon)"
                )
                return .winner(winner)
            }

            // Comparer le nombre de hits
            if blueHits != redHits {
                let winner =
                    blueHits > redHits ? FighterColor.blue : FighterColor.red
                print(
                    "Superiority decided by hits - Winner: \(winner), Blue Hits: \(blueHits), Red Hits: \(redHits)"
                )
                return .winner(winner)
            }

            // Si tout est égal, la décision revient aux arbitres
            print("No superiority found, decision goes to referee")
            return .referee
        }
    }

}

extension Round {
    static func decode(from document: QueryDocumentSnapshot) throws -> Round {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let data = document.data()
        let jsonData = try JSONSerialization.data(withJSONObject: data)

        do {
            let round = try decoder.decode(Round.self, from: jsonData)
            return round
        } catch {
            print(
                "Error decoding round from document \(document.documentID): \(error)"
            )
            throw error
        }
    }
}
