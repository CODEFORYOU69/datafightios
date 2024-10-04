//
//  EventModel.swift
//  datafight
//
//  Created by younes ouasmi on 17/08/2024.
//

import FirebaseFirestore
import Foundation

enum EventType: String, Codable, CaseIterable {
    case open = "Open"
    case regionalChampionship = "Regional Championship"
    case nationalChampionship = "National Championship"
    case continentalChampionship = "Continental Championship"
    case worldChampionship = "World Championship"
    case g1 = "G1"
    case g2 = "G2"
    case grandSlam = "Grand Slam"
    case grandPrix = "Grand Prix"
    case olympicGame = "Olympic Game"
}
struct Event: Codable, Identifiable {
    @DocumentID var id: String?
    var creatorUserId: String
    var eventName: String
    var eventType: EventType
    var location: String
    var date: Date
    var imageURL: String?
    var fightIds: [String]?
    var country: String

    enum CodingKeys: String, CodingKey {
        case id
        case creatorUserId
        case eventName
        case eventType
        case location
        case date
        case imageURL
        case fightIds
        case country
    }

    init(
        id: String? = nil, creatorUserId: String, eventName: String,
        eventType: EventType, location: String, date: Date,
        imageURL: String? = nil, fightIds: [String]? = nil, country: String
    ) {
        self.id = id
        self.creatorUserId = creatorUserId
        self.eventName = eventName
        self.eventType = eventType
        self.location = location
        self.date = date
        self.imageURL = imageURL
        self.fightIds = fightIds
        self.country = country
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        creatorUserId = try container.decode(
            String.self, forKey: .creatorUserId)
        eventName = try container.decode(String.self, forKey: .eventName)
        eventType = try container.decode(EventType.self, forKey: .eventType)
        location = try container.decode(String.self, forKey: .location)
        date = try container.decode(Date.self, forKey: .date)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        fightIds = try container.decodeIfPresent(
            [String].self, forKey: .fightIds)
        country = try container.decode(String.self, forKey: .country)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(creatorUserId, forKey: .creatorUserId)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(location, forKey: .location)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(fightIds, forKey: .fightIds)
        try container.encode(country, forKey: .country)

    }
}
