//
//  FightCategories.swift
//  datafight
//
//  Created by younes ouasmi on 18/08/2024.
//

import Foundation

struct FightCategories {
    static let ageCategories = ["benjamins", "minimes", "cadets", "junior", "senior", "master"]
    static let sexes = ["men", "women"]
    
    static let weightCategories: [String: [String: [String: [String]]]] = [
        "regular": [
            "men": [
                "master": ["-54", "-58", "-63", "-68", "-74", "-80", "-87", "+87"],
                "senior": ["-54", "-58", "-63", "-68", "-74", "-80", "-87", "+87"],
                "junior": ["-45", "-48", "-51", "-55", "-59", "-63", "-68", "-73", "-78", "+78"],
                "cadets": ["-33", "-37", "-41", "-45", "-49", "-53", "-57", "-61", "-65", "+65"],
                "minimes": ["-27", "-30", "-33", "-37", "-41", "-45", "-49", "-53", "-57", "+57"],
                "benjamins": ["-21", "-24", "-27", "-30", "-33", "-37", "-39", "-41", "-44", "+44"]
            ],
            "women": [
                "master": ["-46", "-49", "-53", "-57", "-62", "-67", "-73", "+73"],
                "senior": ["-46", "-49", "-53", "-57", "-62", "-67", "-73", "+73"],
                "junior": ["-42", "-44", "-46", "-49", "-52", "-55", "-59", "-63", "-68", "+68"],
                "cadets": ["-29", "-33", "-37", "-41", "-44", "-47", "-51", "-55", "-59", "+59"],
                "minimes": ["-23", "-26", "-29", "-33", "-37", "-41", "-44", "-47", "-51", "+51"],
                "benjamins": ["-17", "-20", "-23", "-26", "-29", "-33", "-37", "-41", "-44", "+44"]
            ]
        ],
        "olympic": [
            "men": [
                "junior": ["-48", "-55", "-63", "-73", "+73"],
                "senior": ["-58", "-68", "-80", "+80"]
            ],
            "women": [
                "junior": ["-44", "-49", "-55", "-63", "+63"],
                "senior": ["-49", "-57", "-67", "+67"]
            ]
        ]
    ]
    
    static let rounds = ["128ème", "64ème", "32ème", "16ème", "Quarts de finale", "Demi-finale", "Finale", "1er tour de repêchage", "2ème tour de repêchage", "Match pour la 3ème place"]

     static func getWeightCategories(for ageCategory: String, gender: String, isOlympic: Bool) -> [String] {
        let categoryType = isOlympic ? "olympic" : "regular"
        
        if let genderCategories = weightCategories[categoryType]?[gender],
           let ageCategories = genderCategories[ageCategory] {
            return ageCategories
        }
        
        return []
    }
}
