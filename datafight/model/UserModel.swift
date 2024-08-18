//
//  UserModel.swift
//  datafight
//
//  Created by younes ouasmi on 16/08/2024.
//

import FirebaseFirestore
import Foundation

struct User: Codable {
    @DocumentID var id: String?
    var firstName: String
    var lastName: String
    var dateOfBirth: Date?
    var role: String
    var teamName: String
    var country: String
    var profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case dateOfBirth
        case role
        case teamName
        case country
        case profileImageURL
    }

    init(id: String? = nil, firstName: String, lastName: String, dateOfBirth: Date, role: String, teamName: String, country: String, profileImageURL: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.role = role
        self.teamName = teamName
        self.country = country
        self.profileImageURL = profileImageURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        dateOfBirth = try container.decodeIfPresent(Date.self, forKey: .dateOfBirth)
        role = try container.decode(String.self, forKey: .role)
        teamName = try container.decode(String.self, forKey: .teamName)
        country = try container.decode(String.self, forKey: .country)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(role, forKey: .role)
        try container.encode(teamName, forKey: .teamName)
        try container.encode(country, forKey: .country)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
    }
}
