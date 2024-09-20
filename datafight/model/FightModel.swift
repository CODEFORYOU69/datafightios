import FirebaseFirestore
import Foundation

struct Fight:Codable,  Identifiable{
    @DocumentID var id: String?
    var creatorUserId: String
    var eventId: String
    var fightNumber: Int
    var blueFighterId: String
    var redFighterId: String
    var category: String
    var weightCategory: String
    var round: String?
    var isOlympic: Bool
    var roundIds: [String]?
    var fightResult: FightResult?
    var blueVideoReplayUsed: Bool
    var redVideoReplayUsed: Bool
    var videoId: String?
    var videoURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case creatorUserId
        case eventId
        case fightNumber
        case blueFighterId
        case redFighterId
        case category
        case weightCategory
        case round
        case isOlympic
        case roundIds
        case fightResult
        case blueVideoReplayUsed
        case redVideoReplayUsed
        case videoId
        case videoURL
    }

    init(id: String? = nil, creatorUserId: String, eventId: String, fightNumber: Int, blueFighterId: String, redFighterId: String, category: String, weightCategory: String, round: String, isOlympic: Bool, roundIds: [String]? = nil, fightResult: FightResult? = nil, blueVideoReplayUsed: Bool = false, redVideoReplayUsed: Bool = false, videoId: String? = nil, videoURL: String? = nil) {
        self.id = id
        self.creatorUserId = creatorUserId
        self.eventId = eventId
        self.fightNumber = fightNumber
        self.blueFighterId = blueFighterId
        self.redFighterId = redFighterId
        self.category = category
        self.weightCategory = weightCategory
        self.round = round
        self.isOlympic = isOlympic
        self.roundIds = roundIds
        self.fightResult = fightResult
        self.blueVideoReplayUsed = blueVideoReplayUsed
        self.redVideoReplayUsed = redVideoReplayUsed
        self.videoId = videoId
        self.videoURL = videoURL
    }
}

struct FightResult: Codable, CustomStringConvertible {
    var winner: String
    var method: String
    var totalScore: TotalScore

    struct TotalScore: Codable {
        var blue: Int
        var red: Int
    }

    var description: String {
        return "Gagnant : \(winner), Méthode : \(method), Score - Bleu : \(totalScore.blue), Rouge : \(totalScore.red)"
    }

    
    enum CodingKeys: String, CodingKey {
        case winner
        case method
        case totalScore
    }
    
    init(winner: String, method: String, totalScore: (blue: Int, red: Int)) {
        self.winner = winner
        self.method = method
        self.totalScore = TotalScore(blue: totalScore.blue, red: totalScore.red)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        winner = try container.decode(String.self, forKey: .winner)
        method = try container.decode(String.self, forKey: .method)
        totalScore = try container.decode(TotalScore.self, forKey: .totalScore)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(winner, forKey: .winner)
        try container.encode(method, forKey: .method)
        try container.encode(totalScore, forKey: .totalScore)
    }
}

extension Fight {
    init(from entity: FightEntity) {
        self.id = entity.id
        self.creatorUserId = entity.creatorUserId ?? ""
        self.eventId = entity.eventId ?? ""
        self.fightNumber = Int(entity.fightNumber)
        self.blueFighterId = entity.blueFighterId ?? ""
        self.redFighterId = entity.redFighterId ?? ""
        self.category = entity.category ?? ""
        self.weightCategory = entity.weightCategory ?? ""
        self.round = entity.round ?? ""
        self.isOlympic = entity.isOlympic
        self.roundIds = (entity.roundIds )?.components(separatedBy: ",")  // Convertir une chaîne en tableau
        self.blueVideoReplayUsed = entity.blueVideoReplayUsed
        self.redVideoReplayUsed = entity.redVideoReplayUsed
        self.videoId = entity.videoId
        self.videoURL = entity.videoURL

        if let rounds = entity.rounds?.allObjects as? [RoundEntity] {
            var blueRoundsWon = 0
            var redRoundsWon = 0
            var totalBlueScore = 0
            var totalRedScore = 0
            
            for round in rounds {
                if round.roundWinner == self.blueFighterId {
                    blueRoundsWon += 1
                } else if round.roundWinner == self.redFighterId {
                    redRoundsWon += 1
                }
                totalBlueScore += Int(round.blueScore)
                totalRedScore += Int(round.redScore)
            }
            
            if blueRoundsWon >= 2 || redRoundsWon >= 2 {
                let winner = blueRoundsWon > redRoundsWon ? self.blueFighterId : self.redFighterId
                let method = "Points"
                
                self.fightResult = FightResult(
                    winner: winner,
                    method: method,
                    totalScore: (blue: totalBlueScore, red: totalRedScore)
                )
            } else {
                self.fightResult = nil
            }
        } else {
            self.fightResult = nil
        }
    }
}

extension Fight {
    mutating func markVideoReplayAsUsed(for color: FighterColor) {
        if color == .blue {
            blueVideoReplayUsed = true
        } else {
            redVideoReplayUsed = true
        }
    }
    
    func usedVideoReplay(for color: FighterColor) -> Bool {
        return color == .blue ? blueVideoReplayUsed : redVideoReplayUsed
    }
}
extension FightResult {
    var dictionary: [String: Any] {
        return [
            "winner": winner,
            "method": method,
            "totalScore": [
                "blue": totalScore.blue,
                "red": totalScore.red
            ]
        ]
    }
}

