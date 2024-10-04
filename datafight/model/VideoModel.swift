import Foundation

struct Video: Codable {
    let id: String
    let fightId: String
    let url: String
    let duration: Double
    var roundTimestamps: [RoundTimestamp]

    mutating func updateOrAddRoundTimestamp(
        roundNumber: Int, start: TimeInterval, end: TimeInterval?
    ) {
        if let index = roundTimestamps.firstIndex(where: {
            $0.roundNumber == roundNumber
        }) {
            roundTimestamps[index].start = start
            roundTimestamps[index].end = end
        } else {
            let newTimestamp = RoundTimestamp(
                roundNumber: roundNumber, start: start, end: end)
            roundTimestamps.append(newTimestamp)
        }
        roundTimestamps.sort { $0.roundNumber < $1.roundNumber }
    }

    // Default initializer
    init(
        id: String, fightId: String, url: String, duration: Double,
        roundTimestamps: [RoundTimestamp]
    ) {
        self.id = id
        self.fightId = fightId
        self.url = url
        self.duration = duration
        self.roundTimestamps = roundTimestamps
    }

    // Conversion to dictionary for Firestore
    var dictionary: [String: Any] {
        return [
            "id": id,
            "fightId": fightId,
            "url": url,
            "duration": duration,
            "roundTimestamps": roundTimestamps.map { $0.dictionary },
        ]
    }

    // Initialization from a dictionary (useful for retrieving data from Firestore)
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
            let fightId = dictionary["fightId"] as? String,
            let url = dictionary["url"] as? String,
            let duration = dictionary["duration"] as? Double,
            let roundTimestampsDict = dictionary["roundTimestamps"]
                as? [[String: Any]]
        else {
            return nil
        }

        self.id = id
        self.fightId = fightId
        self.url = url
        self.duration = duration
        self.roundTimestamps = roundTimestampsDict.compactMap {
            RoundTimestamp(dictionary: $0)
        }
    }
}

struct RoundTimestamp: Codable {
    let roundNumber: Int
    var start: TimeInterval
    var end: TimeInterval?

    init(roundNumber: Int, start: TimeInterval, end: TimeInterval? = nil) {
        self.roundNumber = roundNumber
        self.start = start
        self.end = end
    }

    // Conversion to dictionary for Firestore
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "roundNumber": roundNumber,
            "start": start,
        ]
        if let end = end {
            dict["end"] = end
        }
        return dict
    }

    // Initialization from a dictionary
    init?(dictionary: [String: Any]) {
        guard let roundNumber = dictionary["roundNumber"] as? Int,
            let start = dictionary["start"] as? TimeInterval
        else {
            return nil
        }

        self.roundNumber = roundNumber
        self.start = start
        self.end = dictionary["end"] as? TimeInterval
    }
}
