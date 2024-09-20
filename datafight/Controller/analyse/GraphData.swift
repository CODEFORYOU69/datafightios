    //
    //  GraphData.swift
    //  datafight
    //
    //  Created by younes ouasmi on 12/09/2024.
    //
    //
    //  GraphData.swift
    //  datafight
    //
    //  Created by younes ouasmi on 12/09/2024.
    //

    import UIKit
    import Foundation
    import FirebaseFirestore
    import Firebase


struct GraphConfiguration: Codable {
    @DocumentID var id: String?
    var name: String
    var visualizationType: VisualizationType
    var dataConfigurations: [ConfiguredData]
    var userId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case visualizationType
        case dataConfigurations
        case userId
    }

    init(id: String? = nil, name: String, visualizationType: VisualizationType, dataConfigurations: [ConfiguredData], userId: String? = nil) {
        self.id = id
        self.name = name
        self.visualizationType = visualizationType
        self.dataConfigurations = dataConfigurations
        self.userId = userId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        visualizationType = try container.decode(VisualizationType.self, forKey: .visualizationType)
        dataConfigurations = try container.decode([ConfiguredData].self, forKey: .dataConfigurations)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(visualizationType, forKey: .visualizationType)
        try container.encode(dataConfigurations, forKey: .dataConfigurations)
        try container.encodeIfPresent(userId, forKey: .userId)
    }
}

    enum SelectionValue: Codable {
        case string(String)
        case int(Int)
        case double(Double)
        case date(Date)
        // Ajoutez d'autres types si nécessaire

        enum CodingKeys: String, CodingKey {
            case type
            case value
        }

        enum ValueType: String, Codable {
            case string
            case int
            case double
            case date
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .string(let value):
                try container.encode(ValueType.string, forKey: .type)
                try container.encode(value, forKey: .value)
            case .int(let value):
                try container.encode(ValueType.int, forKey: .type)
                try container.encode(value, forKey: .value)
            case .double(let value):
                try container.encode(ValueType.double, forKey: .type)
                try container.encode(value, forKey: .value)
            case .date(let value):
                try container.encode(ValueType.date, forKey: .type)
                try container.encode(value, forKey: .value)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ValueType.self, forKey: .type)
            switch type {
            case .string:
                let value = try container.decode(String.self, forKey: .value)
                self = .string(value)
            case .int:
                let value = try container.decode(Int.self, forKey: .value)
                self = .int(value)
            case .double:
                let value = try container.decode(Double.self, forKey: .value)
                self = .double(value)
            case .date:
                let value = try container.decode(Date.self, forKey: .value)
                self = .date(value)
            }
        }
    }

        
struct AnalysisParameter: Codable {
    var entity: EntityType
    var selections: [Selection] = []  // Initialisation vide pour éviter les erreurs
    var filters: [Filter] = []        // Initialisation vide pour éviter les erreurs
}

    struct Selection: Codable {
        var attribute: Attribute
        var value: SelectionValue
    }

    struct Filter: Codable {
        var field: String
        var attribute: Attribute
        var operation: FilterOperation
        var value: SelectionValue
    }

    enum FilterOperation: String, Codable, CaseIterable {
        case equalTo = "Égal à"
        case notEqualTo = "Différent de"
        case greaterThan = "Supérieur à"
        case lessThan = "Inférieur à"
        case contains = "Contient"
    }

    struct Comparison: Codable {
        var parameters: [AnalysisParameter]
        var measure: Measure
        var dateRange: DateRange?
    }

    struct DateRange: Codable {
        var startDate: Date?
        var endDate: Date?
    }

enum VisualizationType: String, Codable, CaseIterable {
    case barChart = "Graphique en barres"
    case lineChart = "Graphique en ligne"
    case pieChart = "Graphique circulaire"
    case scatterPlot = "Nuage de points"
    case radarChart = "Graphique radar"
    var imageName: String {
        switch self {
        case .barChart: return "bar_chart_example"
        case .lineChart: return "line_chart_example"
        case .pieChart: return "pie_chart_example"
        case .scatterPlot: return "scatter_plot_example"
        case .radarChart: return "radar_chart_example"
        }
    }
}
    struct Measure: Codable {
        var type: MeasureType
        var field: Attribute?
        var groupBy: Attribute?
    }

    enum MeasureType: String, CaseIterable, Codable {
        case count = "Count"
        case sum = "Sum"
        case average = "Average"
    }

    enum EntityType: String, Codable, CaseIterable  {
        case fighter = "fighters"
        case fight = "fights"
        case ageCategory = "Category"
        case weightCategory = "weight Category"
        case gender = "gender"
        case eventType = "event type"
        case event = "event"
        case actionType = "action type"
        case round = "Round"
        case actionMoment = "actionmoment"
        case action = "action"
    }
    enum AgeCategoryAttribute: String, Codable, CaseIterable {
        case ageCategory = "Age category"
        
        var databaseKey: String {
            return "Category"
        }
    }
    enum WeightCategoryAttribute: String, Codable, CaseIterable {
        case weightCategory = "weight category"
        
        var databaseKey: String {
            return "weightCategory"
        }
    }
    enum GenderAttribute: String, Codable, CaseIterable {
        case gender = "Gender"
        
        var databaseKey: String {
            return "gender"
        }
    }
    enum EventTypeAttribute: String, Codable, CaseIterable {
        case eventType = "Event type"
        
        var databaseKey: String {
            return "eventType"
        }
    }
    enum ActionTypeAttribute: String, Codable, CaseIterable {
        case actionType = "Type d'action"
        
        var databaseKey: String {
            return "actionType"
        }
    }

    enum Attribute: Codable {
        
        
        case fighter(FighterAttribute)
            case event(EventAttribute)
            case fight(FightAttribute)
            case round(RoundAttribute)
            case action(ActionAttribute)
            case ageCategory(AgeCategoryAttribute)
            case weightCategory(WeightCategoryAttribute)
            case gender(GenderAttribute)
            case eventType(EventTypeAttribute)
            case actionType(ActionTypeAttribute)
        var displayName: String {
                switch self {
                case .fighter(let attr):
                    return attr.rawValue
                case .event(let attr):
                    return attr.rawValue
                case .fight(let attr):
                    return attr.rawValue
                case .round(let attr):
                    return attr.rawValue
                case .action(let attr):
                    return attr.rawValue
                case .ageCategory(let attr):
                    return attr.rawValue
                case .weightCategory(let attr):
                    return attr.rawValue
                case .gender(let attr):
                    return attr.rawValue
                case .eventType(let attr):
                    return attr.rawValue
                case .actionType(let attr):
                    return attr.rawValue
                }
            }

            var databaseKey: String {
                switch self {
                case .fighter(let attr):
                    return attr.databaseKey
                case .event(let attr):
                    return attr.databaseKey
                case .fight(let attr):
                    return attr.databaseKey
                case .round(let attr):
                    return attr.databaseKey
                case .action(let attr):
                    return attr.databaseKey
                case .ageCategory(let attr):
                    return attr.databaseKey
                case .weightCategory(let attr):
                    return attr.databaseKey
                case .gender(let attr):
                    return attr.databaseKey
                case .eventType(let attr):
                    return attr.databaseKey
                case .actionType(let attr):
                    return attr.databaseKey
                }
                
                
            }
        enum CodingKeys: String, CodingKey {
            case type
            case value
        }

        enum AttributeType: String, Codable {
                case fighter
                case event
                case fight
                case round
                case action
                case ageCategory
                case weightCategory
                case gender
                case eventType
                case actionType
            }

        func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .fighter(let value):
                    try container.encode(AttributeType.fighter, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .event(let value):
                    try container.encode(AttributeType.event, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .fight(let value):
                    try container.encode(AttributeType.fight, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .round(let value):
                    try container.encode(AttributeType.round, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .action(let value):
                    try container.encode(AttributeType.action, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .ageCategory(let value):
                    try container.encode(AttributeType.ageCategory, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .weightCategory(let value):
                    try container.encode(AttributeType.weightCategory, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .gender(let value):
                    try container.encode(AttributeType.gender, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .eventType(let value):
                    try container.encode(AttributeType.eventType, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .actionType(let value):
                    try container.encode(AttributeType.actionType, forKey: .type)
                    try container.encode(value, forKey: .value)
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(AttributeType.self, forKey: .type)
                switch type {
                case .fighter:
                    let value = try container.decode(FighterAttribute.self, forKey: .value)
                    self = .fighter(value)
                case .event:
                    let value = try container.decode(EventAttribute.self, forKey: .value)
                    self = .event(value)
                case .fight:
                    let value = try container.decode(FightAttribute.self, forKey: .value)
                    self = .fight(value)
                case .round:
                    let value = try container.decode(RoundAttribute.self, forKey: .value)
                    self = .round(value)
                case .action:
                    let value = try container.decode(ActionAttribute.self, forKey: .value)
                    self = .action(value)
                case .ageCategory:
                    let value = try container.decode(AgeCategoryAttribute.self, forKey: .value)
                    self = .ageCategory(value)
                case .weightCategory:
                    let value = try container.decode(WeightCategoryAttribute.self, forKey: .value)
                    self = .weightCategory(value)
                case .gender:
                    let value = try container.decode(GenderAttribute.self, forKey: .value)
                    self = .gender(value)
                case .eventType:
                    let value = try container.decode(EventTypeAttribute.self, forKey: .value)
                    self = .eventType(value)
                case .actionType:
                    let value = try container.decode(ActionTypeAttribute.self, forKey: .value)
                    self = .actionType(value)
                }
            }
        }


    enum FighterAttribute: String, Codable, CaseIterable {
        case id  // Ajoutez ce cas si nécessaire
        case firstName = "Prénom"
        case lastName = "Nom"
        case gender = "Genre"
        case birthdate = "Date de naissance"
        case country = "Pays"
        case fightIds = "IDs des combats"
        // Ajoutez d'autres attributs si nécessaire

        var databaseKey: String {
            switch self {
            case .id:
                return "fighter id"
            case .firstName:
                return "firstName"
            case .lastName:
                return "lastName"
            case .gender:
                return "gender"
            case .birthdate:
                return "birthdate"
            case .country:
                return "country"
            case .fightIds:
                return "fightIds"
            }
        }
    }

struct ConfiguredData: Codable {
    var parameters: [AnalysisParameter] = []  // Regroupe les paramètres associés ensemble
}

class GraphConfigurationBuilder {
    var configuredData: [ConfiguredData] = []  // Liste des données configurées
    var currentData = ConfiguredData()  // La donnée en cours de configuration
    var visualizationType: VisualizationType?
    var name: String = "Configuration \(Date())"

    func buildGraphConfiguration() -> GraphConfiguration? {
        guard let visualizationType = visualizationType else { return nil }
        return GraphConfiguration(
            name: name,
            visualizationType: visualizationType,

            dataConfigurations: configuredData
        )
    }

    func logConfiguredData() {
        print("===== LOG DES DONNÉES CONFIGURÉES =====")
        for (index, data) in configuredData.enumerated() {
            print("Donnée \(index + 1):")
            for (paramIndex, parameter) in data.parameters.enumerated() {
                print("  Paramètre \(paramIndex + 1):")
                print("    Entité: \(parameter.entity.rawValue)")
                print("    Sélections:")
                for selection in parameter.selections {
                    print("    - \(selection.attribute.displayName) : \(selection.value)")
                }
                print("    Filtres:")
                for filter in parameter.filters {
                    print("    - \(filter.attribute.displayName) \(filter.operation.rawValue) \(filter.value)")
                }
            }
            print("=========================================\n")
        }
    }
}

    


    enum EventAttribute: String, CaseIterable, Codable {
        case id  // Ajoutez ce cas si nécessaire
        case eventName = "Nom de l'événement"
        case eventType = "Type d'événement"
        case location = "Lieu"
        case date = "Date"
        case fightIds = "IDs des combats"
        case country = "Pays"

        var databaseKey: String {
            switch self {
            case .id:
                return " event Id "
            case .eventName:
                return "eventName"
            case .eventType:
                return "eventType"
            case .location:
                return "location"
            case .date:
                return "date"
            case .fightIds:
                return "fightIds"
            case .country:
                return "country"
            }
        }
    }


    enum FightAttribute: String, CaseIterable, Codable {
        case id  // Ajoutez ce cas si nécessaire
        case eventId = "ID de l'événement"
        case fightNumber = "Numéro du combat"
        case blueFighterId = "ID du combattant bleu"
        case redFighterId = "ID du combattant rouge"
        case category = "Catégorie"
        case weightCategory = "Catégorie de poids"
        case round = "Round"
        case isOlympic = "Est olympique"
        case roundIds = "IDs des rounds"
        case fightResult = "Résultat du combat"
        case blueVideoReplayUsed = "Replay vidéo utilisé (bleu)"
        case redVideoReplayUsed = "Replay vidéo utilisé (rouge)"
        case videoId = "ID de la vidéo"
        case creatorUserId = "ID du créateur"
        // Ajoutez d'autres attributs si nécessaire

        var databaseKey: String {
            switch self {
            case .id:
                return "fight id"
            case .eventId:
                return "eventId"
            case .fightNumber:
                return "fightNumber"
            case .blueFighterId:
                return "blueFighterId"
            case .redFighterId:
                return "redFighterId"
            case .category:
                return "category"
            case .weightCategory:
                return "weightCategory"
            case .round:
                return "round"
            case .isOlympic:
                return "isOlympic"
            case .roundIds:
                return "roundIds"
            case .fightResult:
                return "fightResult"
            case .blueVideoReplayUsed:
                return "blueVideoReplayUsed"
            case .redVideoReplayUsed:
                return "isCompleted"
            case .videoId:
                return "videoId"
            case .creatorUserId:
                return "creatorUserId"
            }
        }
    }


    enum RoundAttribute: String, CaseIterable, Codable {
        case roundNumber = "Numéro du round"
        case chronoDuration = "Durée du chrono"
        case duration = "Durée réelle du round avec temps d'arret"
        case roundTime = "temps d'un round"
        case blueFighterId = "ID du combattant bleu"
        case redFighterId = "ID du combattant rouge"
        case isSynced = "Est synchronisé"
        case victoryDecision = "Décision de victoire"
        case roundWinner = "Gagnant du round"
        case blueHits = "Touches bleues"
        case redHits = "Touches rouges"
        case startTime = "Heure de début"
        case endTime = "Heure de fin"
        case blueScore = "Score bleu"
        case redScore = "Score rouge"
        case actions = "Actions"

        var databaseKey: String {
            switch self {
            case .roundNumber:
                return "roundNumber"
            case .chronoDuration:
                return "chronoDuration"
            case .duration:
                return "duration"
            case .roundTime:
                return "roundTime"
            case .blueFighterId:
                return "blueFighterId"
            case .redFighterId:
                return "redFighterId"
            case .isSynced:
                return "isSynced"
            case .victoryDecision:
                return "victoryDecision"
            case .roundWinner:
                return "roundWinner"
            case .blueHits:
                return "blueHits"
            case .redHits:
                return "redHits"
            case .startTime:
                return "startTime"
            case .endTime:
                return "endTime"
            case .blueScore:
                return "blueScore"
            case .redScore:
                return "redScore"
            case .actions:
                return "actions"
            }
        }
    }


    enum ActionAttribute: String, CaseIterable, Codable {
        case fighterId = "ID du combattant"
        case color = "Couleur"
        case actionType = "Type d'action"
        case technique = "Technique"
        case limbUsed = "Membre utilisé"
        case actionZone = "Zone d'action"
        case situation = "Situation de combat"
        case gamjeonType = "Type de Gamjeon"
        case guardPosition = "Position de garde"
        case isActive = "Est actif"
        case chronoTimestamp = "Horodatage chrono"
        case points = "points"  // Attribut virtuel

        // Ajoutez d'autres attributs si nécessaire

        var databaseKey: String {
            switch self {
            case .fighterId:
                return "fighterId"
            case .points:
                return "points"
            
            case .color:
                
                return "color"
            case .actionType:
                return "actionType"
            case .technique:
                return "technique"
            case .limbUsed:
                return "limbUsed"
            case .actionZone:
                return "actionZone"
            case .situation:
                return "situation"
            case .gamjeonType:
                return "gamjeonType"
            case .guardPosition:
                return "guardPosition"
            case .isActive:
                return "isActive"
            case .chronoTimestamp:
                return "chronoTimestamp"
            }
        }
        
    }



    extension Attribute {
        static func from(entity: EntityType) -> Attribute? {
            switch entity {
            case .gender:
                return .gender(.gender)
            case .eventType:
                return .eventType(.eventType)
            case .actionType:
                return .actionType(.actionType)
            default:
                return nil
            }
        }
    }
