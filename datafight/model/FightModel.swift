//
//  FightModel.swift
//  datafight
//
//  Created by younes ouasmi on 18/08/2024.
//

import FirebaseFirestore
import Foundation

struct Fight: Codable {
    @DocumentID var id: String?
    var creatorUserId: String
    var eventId: String
    var blueFighterId: String
    var redFighterId: String
    var category: String
    var weightCategory: String
    var round: String
    var isOlympic: Bool
    var roundIds: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case creatorUserId
        case eventId
        case blueFighterId
        case redFighterId
        case category
        case weightCategory
        case round
        case isOlympic
        case roundIds
    }

    init(id: String? = nil, creatorUserId: String, eventId: String, blueFighterId: String, redFighterId: String, category: String, weightCategory: String, round: String, isOlympic: Bool, roundIds: [String]? = nil) {
        self.id = id
        self.creatorUserId = creatorUserId
        self.eventId = eventId
        self.blueFighterId = blueFighterId
        self.redFighterId = redFighterId
        self.category = category
        self.weightCategory = weightCategory
        self.round = round
        self.isOlympic = isOlympic
        self.roundIds = roundIds
    }
}
