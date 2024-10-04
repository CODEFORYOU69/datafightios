//
//  FighterModel.swift
//  datafight
//
//  Created by younes ouasmi on 17/08/2024.
//

import FirebaseFirestore
import Foundation

struct Fighter: Codable, Identifiable {
    @DocumentID var id: String?
    var creatorUserId: String
    var firstName: String
    var lastName: String
    var gender: String
    var birthdate: Date?
    var country: String
    var profileImageURL: String?
    var fightIds: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case creatorUserId
        case firstName
        case lastName
        case gender
        case birthdate
        case country
        case profileImageURL
        case fightIds

    }

    init(
        id: String? = nil, creatorUserId: String, firstName: String,
        lastName: String, gender: String, birthdate: Date?, country: String,
        profileImageURL: String? = nil, fightIds: [String]? = nil
    ) {
        self.id = id
        self.creatorUserId = creatorUserId
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.birthdate = birthdate
        self.country = country
        self.profileImageURL = profileImageURL
        self.fightIds = fightIds

    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        creatorUserId = try container.decode(
            String.self, forKey: .creatorUserId)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        gender = try container.decode(String.self, forKey: .gender)
        birthdate = try container.decodeIfPresent(Date.self, forKey: .birthdate)
        country = try container.decode(String.self, forKey: .country)
        profileImageURL = try container.decodeIfPresent(
            String.self, forKey: .profileImageURL)
        fightIds = try container.decodeIfPresent(
            [String].self, forKey: .fightIds)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(creatorUserId, forKey: .creatorUserId)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(gender, forKey: .gender)
        try container.encodeIfPresent(birthdate, forKey: .birthdate)
        try container.encode(country, forKey: .country)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encodeIfPresent(fightIds, forKey: .fightIds)

    }
}
