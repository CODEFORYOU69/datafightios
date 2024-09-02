import Foundation

struct Video: Codable {
    let id: String
    let fightId: String
    let url: String
    let duration: Double
    var roundTimestamps: [RoundTimestamp]

    // Initialiseur par défaut
    init(id: String, fightId: String, url: String, duration: Double, roundTimestamps: [RoundTimestamp]) {
        self.id = id
        self.fightId = fightId
        self.url = url
        self.duration = duration
        self.roundTimestamps = roundTimestamps
    }

    // Conversion en dictionnaire pour Firestore
    var dictionary: [String: Any] {
        return [
            "id": id,
            "fightId": fightId,
            "url": url,
            "duration": duration,
            "roundTimestamps": roundTimestamps.map { $0.dictionary }
        ]
    }

    // Initialisation à partir d'un dictionnaire (utile pour récupérer des données depuis Firestore)
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let fightId = dictionary["fightId"] as? String,
              let url = dictionary["url"] as? String,
              let duration = dictionary["duration"] as? Double,
              let roundTimestampsDict = dictionary["roundTimestamps"] as? [[String: Any]] else {
            return nil
        }

        self.id = id
        self.fightId = fightId
        self.url = url
        self.duration = duration
        self.roundTimestamps = roundTimestampsDict.compactMap { RoundTimestamp(dictionary: $0) }
    }
}

struct RoundTimestamp: Codable {
    let roundNumber: Int
    let start: TimeInterval
    let end: TimeInterval?

    // Conversion en dictionnaire pour Firestore
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "roundNumber": roundNumber,
            "start": start
        ]
        if let end = end {
            dict["end"] = end
        }
        return dict
    }

    // Initialisation à partir d'un dictionnaire
    init?(dictionary: [String: Any]) {
        guard let roundNumber = dictionary["roundNumber"] as? Int,
              let start = dictionary["start"] as? TimeInterval else {
            return nil
        }

        self.roundNumber = roundNumber
        self.start = start
        self.end = dictionary["end"] as? TimeInterval
    }
}
