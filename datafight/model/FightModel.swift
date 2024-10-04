import FirebaseFirestore
import Foundation

struct Fight: Codable, Identifiable {
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
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(creatorUserId, forKey: .creatorUserId)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(fightNumber, forKey: .fightNumber)
        try container.encode(blueFighterId, forKey: .blueFighterId)
        try container.encode(redFighterId, forKey: .redFighterId)
        try container.encode(category, forKey: .category)
        try container.encode(weightCategory, forKey: .weightCategory)
        try container.encodeIfPresent(round, forKey: .round)
        try container.encode(isOlympic, forKey: .isOlympic)
        try container.encodeIfPresent(roundIds, forKey: .roundIds)
        try container.encodeIfPresent(fightResult, forKey: .fightResult)
        try container.encode(blueVideoReplayUsed, forKey: .blueVideoReplayUsed)
        try container.encode(redVideoReplayUsed, forKey: .redVideoReplayUsed)
        try container.encodeIfPresent(videoId, forKey: .videoId)
        try container.encodeIfPresent(videoURL, forKey: .videoURL)
    }
    init(
        id: String? = nil, creatorUserId: String, eventId: String,
        fightNumber: Int, blueFighterId: String, redFighterId: String,
        category: String, weightCategory: String, round: String,
        isOlympic: Bool, roundIds: [String]? = nil,
        fightResult: FightResult? = nil, blueVideoReplayUsed: Bool = false,
        redVideoReplayUsed: Bool = false, videoId: String? = nil,
        videoURL: String? = nil
    ) {
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
        return
            "Gagnant : \(winner), Méthode : \(method), Score - Bleu : \(totalScore.blue), Rouge : \(totalScore.red)"
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

    // Pas besoin de redéfinir init(from:) et encode(to:) car Codable les génère automatiquement

    // Ajout d'une méthode pour convertir en dictionnaire
    var dictionary: [String: Any] {
        return [
            "winner": winner,
            "method": method,
            "totalScore": [
                "blue": totalScore.blue,
                "red": totalScore.red,
            ],
        ]
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
