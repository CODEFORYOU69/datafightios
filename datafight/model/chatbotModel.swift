//
//  chatbotModel.swift
//  datafight
//
//  Created by younes ouasmi on 13/09/2024.
//

import Foundation
import DGCharts


enum MessageSender {
    case user
    case bot
}

struct ChatMessage {
    let sender: MessageSender
    let content: String
}
class ChatBotManager {
    var availableEntities: [String: Any] = [:]
    
    enum ConversationStep: Equatable {
        case selectVisualizationType
        case selectEntity
        case chooseRelatedEntity
        case chooseRelatedEntityorfinish
        case selectDataCount
        case configureData(Int) // Le nombre de données à configurer
        case configurePlotOptions
        case confirmConfiguration
        case chooseParameterAction
        case selectSpecificEntity
        case selectAttribute
        case selectAttributeValue
        case addFilter
        case confirmParameter
        case addAnotherParameter
        case defineComparison
        case selectVisualization
        case enterConfigurationName
        case waitingForMultipleSelection
        case selectBarChartOptions
        case selectLineChartOptions
        case selectPieChartOptions
        case selectScatterPlotOptions
        case selectRadarChartOptions
        case selectWeightCategory
        case selectCategory
        case selectGender
        case selectOlympicCategory
        case preview
        case configureChartTitle
        case configureXAxisLabel
        case configureYAxisLabel
        case configureLegend
        case configureAnimation
        case configureChartSpecificOptions
        case end
    }
    
    
    var currentStep: ConversationStep = .selectVisualizationType
    var graphConfigurationBuilder = GraphConfigurationBuilder()
    var currentParameter: AnalysisParameter?
    var currentDataIndex: Int = 0
    
    var requiredDataSets: Int = 1
    
    var currentAttribute: Attribute?
    var currentSelection: Selection?
    private enum BarChartOption {
        case orientation, groupSpacing, showValues
    }

    private enum LineChartOption {
        case lineType, lineWidth, fillEnabled
    }
    
   

    private enum PieChartOption {
        case holeRadius, showPercentages
    }

    private enum ScatterPlotOption {
        case shapeType, showTrendLine
    }

    private enum RadarChartOption {
        case fillEnabled, rotationEnabled
    }

    private var currentBarChartOption: BarChartOption? = .orientation
    private var currentLineChartOption: LineChartOption? = .lineType
    private var currentPieChartOption: PieChartOption? = .holeRadius
    private var currentScatterPlotOption: ScatterPlotOption? = .shapeType
    private var currentRadarChartOption: RadarChartOption? = .fillEnabled
    
    func getBotMessage() -> String {
        switch currentStep {
        case .selectVisualizationType:
            return "Quel type de graphique souhaitez-vous créer ?"
        case .selectEntity:
            return "Que souhaitez-vous analyser ?"
        case .selectCategory:
            return "Quelle catégorie souhaitez-vous analyser ?"
         case .selectGender:
            return "Choisissez le sexe (hommes ou femmes) :"
        case .selectWeightCategory:
            return "Quelle catégorie de poids souhaitez-vous analyser ?"
        case .selectOlympicCategory:
            return "Seulement les catégories olympiques ?"
        case .chooseRelatedEntityorfinish:
            return "Voulez-vous terminer la configuration de cette donnée ou  affiner ce paramètre ?"
        case .chooseRelatedEntity:
            return "choisissez une nouvelle entité pour affinez votre donnee "
        case .chooseParameterAction:
            return "Voulez-vous sélectionner un \(currentParameter?.mainEntity.rawValue ?? "élément") spécifique ou affiner ce paramètre ?"
        case .configurePlotOptions:
            return "Souhaitez-vous configurer des options spécifiques pour le graphique ? (Oui/Non)"

        case .selectDataCount:
            let minRequired = graphConfigurationBuilder.getMinimumRequiredDataCount()
            return "Combien de séries de données souhaitez-vous inclure ? (Minimum requis : \(minRequired))"
        case .configureData(let totalCount):
            return "Configurons la donnée \(currentDataIndex + 1) sur \(totalCount). Quelle entité souhaitez-vous analyser ?"
        case .selectAttribute:
            return "Quel attribut souhaitez-vous spécifier ?"
        case .selectAttributeValue:
            return "Veuillez choisir une valeur pour l'attribut."
        case .addFilter:
            return "Voulez-vous ajouter un filtre à cette donnée ?"
        case .confirmParameter:
            graphConfigurationBuilder.configuredData.append(graphConfigurationBuilder.currentData)
                
                // Réinitialiser currentData pour la prochaine configuration
                graphConfigurationBuilder.currentData = ConfiguredData()
                
                // Afficher la configuration actuelle
                let configuredDataMessage = displayConfiguredData()
                return "Voici le paramètre que vous avez configuré. Voulez-vous le confirmer ?\n\n\(configuredDataMessage)"
        case .defineComparison:
            return "Comment souhaitez-vous comparer les paramètres ?"
        case .selectVisualization:
            return "Quel type de graphique souhaitez-vous utiliser ?"
        case .preview:
            return "Voici un aperçu du graphique."
        case .enterConfigurationName:
            return "Veuillez entrer un nom pour votre configuration."
        case .end:
            return "La configuration est terminée."
        case .selectSpecificEntity:
            return "Choisissez une entité spécifique"
        case .addAnotherParameter:
            return "Voulez-vous ajouter un autre paramètre ?"
        case .waitingForMultipleSelection:
            return "Sélectionnez une ou plusieurs valeurs"
        case .selectBarChartOptions:
            return "Voulez-vous afficher les barres pleines ? (Oui/Non)"
        case .selectLineChartOptions:
            return "Voulez-vous afficher les lignes en pointillés ? (Oui/Non)"
        case .selectPieChartOptions:
            return "Voulez-vous afficher les étiquettes de chaque secteur ? (Oui/Non)"
        case .selectScatterPlotOptions:
            return "Voulez-vous afficher les points avec des couleurs différentes ? (Oui/Non)"
        case .selectRadarChartOptions:
            return "Voulez-vous afficher les axes avec des étiquettes ? (Oui/Non)"
        case .configureChartTitle:
               return "Entrez le titre du graphique"
           case .configureXAxisLabel:
               return "Entrez le label de l'axe X"
           case .configureYAxisLabel:
               return "Entrez le label de l'axe Y"
           case .configureLegend:
               return "Voulez-vous afficher la légende ? (Oui/Non)"
           case .configureAnimation:
               return "Voulez-vous activer l'animation ? (Oui/Non)"
        case .configureChartSpecificOptions:
            if let visualizationType = graphConfigurationBuilder.visualizationType {
                switch visualizationType {
                case .barChart:
                    if let option = currentBarChartOption {
                        switch option {
                        case .orientation:
                            return "Comment souhaitez-vous orienter vos barres ? (Verticales/Horizontales)"
                        case .groupSpacing:
                            return "Quel espacement entre les groupes de barres souhaitez-vous ? (Entrez une valeur numérique)"
                        case .showValues:
                            return "Voulez-vous afficher les valeurs sur les barres ? (Oui/Non)"
                        }
                    }
                case .lineChart:
                    if let option = currentLineChartOption {
                        switch option {
                        case .lineType:
                            return "Quel type de ligne souhaitez-vous utiliser ? (Droite/Courbe/Escalier)"
                        case .lineWidth:
                            return "Quelle épaisseur de ligne souhaitez-vous ? (Entrez une valeur numérique)"
                        case .fillEnabled:
                            return "Voulez-vous remplir sous la ligne ? (Oui/Non)"
                        }
                    }
                case .pieChart:
                    if let option = currentPieChartOption {
                        switch option {
                        case .holeRadius:
                            return "Quel rayon souhaitez-vous pour le trou central du diagramme circulaire ? (Entrez une valeur numérique)"
                        case .showPercentages:
                            return "Voulez-vous afficher les pourcentages sur le graphique ? (Oui/Non)"
                        }
                    }
                case .scatterPlot:
                    if let option = currentScatterPlotOption {
                        switch option {
                        case .shapeType:
                            return "Quelle forme souhaitez-vous pour les points ? (Cercle/Carré/Triangle)"
                        case .showTrendLine:
                            return "Souhaitez-vous ajouter une ligne de tendance ? (Oui/Non)"
                        }
                    }
                case .radarChart:
                           if let option = currentRadarChartOption {
                               switch option {
                               case .fillEnabled:
                                   return "Voulez-vous remplir les zones entre les axes ? (Oui/Non)"
                               case .rotationEnabled:
                                   return "Voulez-vous activer la rotation du graphique ? (Oui/Non)"
                               }
                           }
                       }
                   }
                   // Add this return statement to ensure a String is returned
                   return ""


        case .confirmConfiguration:
            return "Voici un résumé de votre configuration. Voulez-vous confirmer ?"
        }
    }
    
    func getOptions(completion: @escaping ([String]) -> Void) {
        switch currentStep {
        case .selectEntity:
            print("Étape actuelle : \(currentStep)")
            completion(EntityType.allCases.map { $0.rawValue })
        case .chooseParameterAction:
            if let entityName = currentParameter?.mainEntity.rawValue {
                completion(["Sélectionner un \(entityName)", "Affiner le paramètre"])
            } else {
                completion([])
            }
         case .selectCategory:
            completion(FightCategories.ageCategories)
        case .selectGender:
            completion(FightCategories.sexes)
        case .selectWeightCategory:
            if let ageCategory = currentParameter?.selections.first(where: { $0.attribute == .ageCategory(.ageCategory) })?.value.toString(),
               let gender = currentParameter?.selections.first(where: { $0.attribute == .gender(.gender) })?.value.toString(),
               let isOlympic = currentParameter?.filters.first(where: { $0.field == "isOlympic" })?.value.toBool() {
                let categories = FightCategories.getWeightCategories(for: ageCategory, gender: gender, isOlympic: isOlympic)
                completion(categories)
            } else {
                completion([])
            }
        case .selectOlympicCategory:
            completion(["Oui", "Non"])
        case .confirmParameter:
            completion(["Confirmer", "Annuler"])
        case .addAnotherParameter:
            completion(["Oui", "Non"])
            
        case .selectAttribute:
            let attributes = getRelevantAttributes().map { $0.displayName }
            completion(attributes)
            
        case .selectSpecificEntity:
            if let entity = currentParameter?.mainEntity {
                fetchEntityNames(for: entity) { entityNames in
                    completion(entityNames)
                }
            } else {
                completion([])
            }
        case .chooseRelatedEntity:
                completion(EntityType.allCases.map { $0.rawValue })
        case .chooseRelatedEntityorfinish:
            completion(["Terminer", "add filter"])
        case .addFilter:
            completion(["Oui", "Non"])
        case .selectVisualization:
            completion(["Graphique en barres", "Graphique en ligne", "Graphique radar"])
        case .selectAttributeValue, .waitingForMultipleSelection:
            if let attribute = currentAttribute {
                fetchAttributeValues(for: attribute) { values in
                    completion(values)
                }
            } else {
                completion([])
            }
        case .selectDataCount:
            completion(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]) // Ou toute autre plage logique
        case .configureData:
            completion(EntityType.allCases.map { $0.rawValue })
        case .configurePlotOptions:
            // Fournissez des options générales si nécessaire, ou laissez vide si l'utilisateur doit simplement entrer une valeur
            completion(["Oui", "Non"])

        case .configureChartTitle:
            completion([]) // Renvoie une liste vide pour afficher un champ de texte
            case .configureXAxisLabel:
            completion([]) // Renvoie une liste vide pour afficher un champ de texte
            case .configureYAxisLabel:
            completion([]) // Renvoie une liste vide pour afficher un champ de texte
            case .configureLegend:
                completion(["Oui", "Non"])
            case .configureAnimation:
                completion(["Oui", "Non"])
        case .configureChartSpecificOptions:
            if let visualizationType = graphConfigurationBuilder.visualizationType {
                switch visualizationType {
                case .barChart:
                    if let option = currentBarChartOption {
                        switch option {
                        case .orientation:
                            completion(["Verticales", "Horizontales"])
                        case .groupSpacing:
                            completion([]) // Renvoie une liste vide pour afficher un champ de texte
                        case .showValues:
                            completion(["Oui", "Non"])
                        }
                    }
                case .lineChart:
                    if let option = currentLineChartOption {
                        switch option {
                        case .lineType:
                            completion(["Droite", "Courbe", "Escalier"])
                        case .lineWidth:
                            completion([]) // Renvoie une liste vide pour afficher un champ de texte
                        case .fillEnabled:
                            completion(["Oui", "Non"])
                        }
                    }
                case .pieChart:
                    if let option = currentPieChartOption {
                        switch option {
                        case .holeRadius:
                            completion([]) // Renvoie une liste vide pour afficher un champ de texte
                        case .showPercentages:
                            completion(["Oui", "Non"])
                        }
                    }
                case .scatterPlot:
                    if let option = currentScatterPlotOption {
                        switch option {
                        case .shapeType:
                            completion(["Cercle", "Carré", "Triangle"])
                        case .showTrendLine:
                            completion(["Oui", "Non"])
                        }
                    }
                case .radarChart:
                    if let option = currentRadarChartOption {
                        switch option {
                        case .fillEnabled:
                            completion(["Oui", "Non"])
                        case .rotationEnabled:
                            completion(["Oui", "Non"])
                        }
                    }
                }
            } else {
                completion([])
            }


        case .selectBarChartOptions:
            completion(["Oui", "Non"])
        case .enterConfigurationName:
        // Ajoutez ici une méthode pour récupérer le nom de la configuration
        
            completion([]) // Renvoie une liste vide pour afficher un champ de texte
        case .selectLineChartOptions:
            completion(["Oui", "Non"])
        case .selectPieChartOptions:
            completion(["Oui", "Non"])
        case .selectScatterPlotOptions:
            completion(["Oui", "Non"])
        case .selectRadarChartOptions:
            completion(["Oui", "Non"])
        case .confirmConfiguration:
            completion(["Confirmer", "Modifier"])
        case .end:
            completion(["Créer une nouvelle analyse", "Visualiser les résultats", "Retourner au menu principal"])
        default:
            completion([])
        }
    }
    
    private func getChartSpecificOptions(completion: @escaping ([String]) -> Void) {
        switch graphConfigurationBuilder.visualizationType {
        case .barChart:
            completion(["Orientation (Verticale/Horizontale)", "Espacement entre groupes", "Afficher les valeurs sur les barres"])
        case .lineChart:
            completion(["Type de ligne (Droite/Courbe/Escalier)", "Épaisseur de ligne", "Remplissage sous la ligne"])
        case .pieChart:
            completion(["Rayon du trou central", "Afficher les pourcentages"])
        case .scatterPlot:
            completion(["Forme des points", "Afficher une ligne de tendance"])
        case .radarChart:
            completion(["Remplissage activé", "Rotation activée"])
        case.none:
            currentStep = .confirmConfiguration

            
        }
    }
    func fetchEntityNames(for entity: EntityType, completion: @escaping ([String]) -> Void) {
        switch entity {
        case .fighter:
            // Utilisation de la méthode personnalisée getFighters
            FirebaseService.shared.getFighters { result in
                switch result {
                case .success(let fighters):
                    // Stocker les entités pour une utilisation ultérieure
                    self.availableEntities = [:]
                    let names = fighters.map { fighter in
                        let name = "\(fighter.firstName) \(fighter.lastName)"
                        self.availableEntities[name] = fighter
                        return name
                    }
                    completion(names)
                case .failure(let error):
                    print("Erreur lors de la récupération des combattants : \(error)")
                    completion([])
                }
            }
            
        case .event:
            // Utilisation de la méthode personnalisée getEvents
            FirebaseService.shared.getEvents { result in
                switch result {
                case .success(let events):
                    self.availableEntities = [:]
                    let names = events.map { event in
                        let name = event.eventName
                        self.availableEntities[name] = event
                        return name
                    }
                    completion(names)
                case .failure(let error):
                    print("Erreur lors de la récupération des événements : \(error)")
                    completion([])
                }
            }
            
        case .fight:
            // Utilisation de la méthode personnalisée getFights
            FirebaseService.shared.getFights { result in
                switch result {
                case .success(let fights):
                    self.availableEntities = [:]
                    let names = fights.map { fight in
                        let name = "Fight \(fight.fightNumber)"
                        self.availableEntities[name] = fight
                        return name
                    }
                    completion(names)
                case .failure(let error):
                    print("Erreur lors de la récupération des combats : \(error)")
                    completion([])
                }
            }
            
        default:
            completion([])
        }
    }
    
    
    func fetchAttributeValues(for attribute: Attribute, completion: @escaping ([String]) -> Void) {
        switch attribute {
        case .fighter(let fighterAttribute):
            let collectionName = "fighters"
            let fieldName = fighterAttribute.databaseKey
            FirebaseService.shared.fetchDistinctValues(from: collectionName, field: fieldName) { result in
                switch result {
                case .success(let values):
                    completion(values)
                case .failure(let error):
                    print("Erreur lors de la récupération des valeurs : \(error.localizedDescription)")
                    completion([])
                }
            }
        case .fight(let fightAttribute):
            let collectionName = "fights"
            let fieldName = fightAttribute.databaseKey
            FirebaseService.shared.fetchDistinctValues(from: collectionName, field: fieldName) { result in
                switch result {
                case .success(let values):
                    completion(values)
                case .failure(let error):
                    print("Erreur lors de la récupération des valeurs : \(error.localizedDescription)")
                    completion([])
                }
            }
        case .event(let eventAttribute):
            let collectionName = "events"
            let fieldName = eventAttribute.databaseKey
            FirebaseService.shared.fetchDistinctValues(from: collectionName, field: fieldName) { result in
                switch result {
                case .success(let values):
                    completion(values)
                case .failure(let error):
                    print("Erreur lors de la récupération des valeurs : \(error.localizedDescription)")
                    completion([])
                }
            }
        case .action(let actionAttribute):
            switch actionAttribute {
            case .fighterId:
                // Récupérer les IDs ou les noms des combattants
                FirebaseService.shared.fetchDistinctValues(from: "actions", field: "fighterId") { result in
                    switch result {
                    case .success(let values):
                        completion(values)
                    case .failure(let error):
                        print("Erreur lors de la récupération des valeurs : \(error.localizedDescription)")
                        completion([])
                    }
                }
            case .color:
                completion(FighterColor.allCases.map { $0.rawValue })
            case .actionType:
                completion(ActionType.allCases.map { $0.rawValue })
            case .technique:
                completion(Technique.allCases.map { $0.rawValue })
            case .limbUsed:
                completion(Limb.allCases.map { $0.rawValue })
            case .actionZone:
                completion(Zone.allCases.map { $0.rawValue })
            case .situation:
                completion(CombatSituation.allCases.map { $0.rawValue })
            case .gamjeonType:
                completion(GamjeonType.allCases.map { $0.rawValue })
            case .guardPosition:
                completion(GuardPosition.allCases.map { $0.rawValue })
            case .isActive:
                completion(["true", "false"])
            case .points:
                completion(["1", "2", "3", "4", "5"])
            case .chronoTimestamp:
                // Proposer des plages de temps ou des intervalles
                completion(["0-30s", "31-60s", "61-90s", "91-120s"])
            }
        case .ageCategory:
        completion(FightCategories.ageCategories)
   case .weightCategory:
    if let ageCategory = currentParameter?.selections.first(where: { $0.attribute == .ageCategory(.ageCategory) })?.value.toString(),
       let gender = currentParameter?.selections.first(where: { $0.attribute == .gender(.gender) })?.value.toString(),
       let isOlympic = currentParameter?.filters.first(where: { $0.field == "isOlympic" })?.value.toBool() {
        let categories = FightCategories.getWeightCategories(for: ageCategory, gender: gender, isOlympic: isOlympic)
        completion(categories)
    } else {
        // Fallback to all unique weight categories if we don't have all the information
        let allWeightCategories = Set(FightCategories.weightCategories.values.flatMap { $0.values }.flatMap { $0.values }.flatMap { $0 })
        completion(Array(allWeightCategories).sorted())
    }
    case .gender:
        completion(FightCategories.sexes)
        case .eventType:
            completion(EventType.allCases.map { $0.rawValue })
        case .actionType:
            completion(ActionType.allCases.map { $0.rawValue })
        default:
            completion([])
        }
    }
    
    func allowsMultipleSelection(for attribute: Attribute) -> Bool {
        print("allowsMultipleSelection(for:) appelé avec l'attribut : \(attribute)")
        
        let result: Bool
        switch attribute {
        case .action(let actionAttribute):
            switch actionAttribute {
            case .actionType, .technique, .limbUsed, .actionZone, .situation, .gamjeonType:
                print("Multiple sélection autorisée pour l'attribut d'action : \(actionAttribute)")
                result = true
            default:
                print("Multiple sélection non autorisée pour l'attribut d'action : \(actionAttribute)")
                result = false
            }
            // ... autres cas ...
        default:
            print("Multiple sélection non autorisée pour l'attribut : \(attribute)")
            result = false
        }
        
        print("Résultat de allowsMultipleSelection(for:) : \(result)")
        return result
    }
    func processMultipleSelections(_ selections: [String]) {
        print("processMultipleSelections appelé avec : \(selections)")
        if let attribute = currentAttribute {
            print("Attribut courant : \(attribute)")
            let newSelections = selections.map { Selection(attribute: attribute, value: .string($0)) }
            currentParameter?.selections.append(contentsOf: newSelections)
            print("Nouvelles sélections ajoutées : \(newSelections)")
            currentAttribute = nil
            currentStep = .addFilter
            print("Passage à l'étape de raffinage du paramètre")
        } else {
            print("Aucun attribut courant")
        }
    }
    
    func allowsMultipleSelection() -> Bool {
        print("allowsMultipleSelection() appelé")
        print("Étape actuelle : \(currentStep)")
        
        let result: Bool
        switch currentStep {
        case .selectEntity:
            print("Étape selectEntity : multiple sélection non autorisée")
            result = false
        case .selectAttributeValue:
            if let attribute = currentAttribute {
                print("Étape selectAttributeValue avec attribut : \(attribute)")
                result = allowsMultipleSelection(for: attribute)
                print("Multiple sélection autorisée pour cet attribut : \(result)")
            } else {
                print("Étape selectAttributeValue sans attribut : multiple sélection non autorisée")
                result = false
            }
        case .waitingForMultipleSelection:
            print("Étape waitingForMultipleSelection : multiple sélection autorisée")
            result = true
        default:
            print("Étape par défaut : \(currentStep), multiple sélection non autorisée")
            result = false
        }
        
        print("Résultat final de allowsMultipleSelection : \(result)")
        return result
    }
    func getRequiredDataSets(for visualizationType: VisualizationType) -> Int {
        switch visualizationType {
        case .barChart:
            return 1
        case .lineChart:
            return 1
        case .pieChart:
            return 1
        case .scatterPlot:
            return 2
        case .radarChart:
            return 1
        }
    }
    
    func processUserSelection(_ selection: String) {
        print("processUserSelection appelé avec : \(selection)")
        print("Étape actuelle avant traitement : \(currentStep)")
        
        switch currentStep {
        case .selectVisualizationType:
            if let visualizationType = VisualizationType(rawValue: selection) {
                graphConfigurationBuilder.visualizationType = visualizationType
                currentStep = .selectDataCount
            }
        case .selectDataCount:
            if let count = Int(selection), graphConfigurationBuilder.isValidDataCount(count) {
                requiredDataSets = count
                currentDataIndex = 0
                currentStep = .configureData(count)
            }
        case .configureData:
            if let entity = EntityType(rawValue: selection) {
                print("Entité sélectionnée : \(entity)")
                currentParameter = AnalysisParameter(mainEntity: entity)
                switch entity {
                case .gender, .eventType, .actionType:
                    print("Passage direct à la sélection de valeur d'attribut")
                    currentAttribute = Attribute.from(entity: entity)
                    currentStep = .selectAttributeValue
                case .fighter, .fight, .event:
                    print("Passage à l'étape de choix d'action sur le paramètre")
                    currentStep = .chooseParameterAction
                case .category:
                    print("Passage à l'étape de choix d'action sur le paramètre")
                    currentStep = .selectCategory
                default:
                    print("Passage à l'étape de raffinage du paramètre")
                    currentStep = .addFilter
                }
            }
            
        case .selectEntity:
            print("Traitement de la sélection d'entité")
            if let entity = EntityType(rawValue: selection) {
                print("Entité principale sélectionnée : \(entity)")
                currentParameter = AnalysisParameter(mainEntity: entity)
                print("parametre actuelle : \(String(describing: currentParameter))")

                switch entity {
                case .gender, .eventType, .actionType:
                    print("Passage direct à la sélection de valeur d'attribut")
                    currentAttribute = Attribute.from(entity: entity)
                    currentStep = .selectAttributeValue
                case .fighter, .fight, .event:
                    print("Passage à l'étape de choix d'action sur le paramètre")
                    currentStep = .chooseParameterAction
                default:
                    print("Passage à l'étape de raffinage du paramètre")
                    currentStep = .addFilter
                }
            } else {
                print("Entité non reconnue : \(selection)")
            }
        case .selectCategory:
            currentParameter?.selections.append(Selection(attribute: .ageCategory(.ageCategory), value: .string(selection)))
            currentStep = .selectGender
        case .selectGender:
            currentParameter?.selections.append(Selection(attribute: .gender(.gender), value: .string(selection)))
            currentStep = .selectOlympicCategory
        case .selectOlympicCategory:
            let isOlympic = selection.lowercased() == "oui"
            currentParameter?.filters.append(Filter(field: "isOlympic", attribute: .fight(.isOlympic), operation: .equalTo, value: .bool(isOlympic)))
            currentStep = .selectWeightCategory
        case .selectWeightCategory:
            if let ageCategory = currentParameter?.selections.first(where: { $0.attribute == .ageCategory(.ageCategory) })?.value.toString(),
               let gender = currentParameter?.selections.first(where: { $0.attribute == .gender(.gender) })?.value.toString(),
               let isOlympic = currentParameter?.filters.first(where: { $0.field == "isOlympic" })?.value.toBool() {
                let categories = FightCategories.getWeightCategories(for: ageCategory, gender: gender, isOlympic: isOlympic)
                if categories.contains(selection) {
                    currentParameter?.selections.append(Selection(attribute: .weightCategory(.weightCategory), value: .string(selection)))
                    currentStep = .confirmParameter
                }
            }
        case .chooseParameterAction:
            print("Traitement du choix d'action sur le paramètre")
            if selection.starts(with: "Sélectionner un") {
                print("parametre actuelle : \(String(describing: currentParameter))")

                print("Passage à la sélection d'entité spécifique")
                currentStep = .selectSpecificEntity
            } else if selection == "Affiner le paramètre" {
                print("Passage au raffinage du paramètre")
                currentStep = .selectAttribute
            }
        case .selectSpecificEntity:
            if let selectedEntity = availableEntities[selection] {
                print("parametre actuelle : \(String(describing: currentParameter))")

                currentParameter?.specificEntityId = getEntityId(selectedEntity)
                currentStep = .chooseRelatedEntityorfinish
                
            } else {
                print("Entité spécifique non trouvée : \(selection)")
            }
            
        case .chooseRelatedEntityorfinish:
            if selection == "Terminer" {
                print("parametre actuelle : \(String(describing: currentParameter))")

                currentStep = .confirmParameter
            } else {
                currentStep = .chooseRelatedEntity
            }
        case .addFilter:
            if selection == "Oui" {
                print("parametre actuelle : \(String(describing: currentParameter))")

                if currentParameter?.specificEntityId != nil {
                    currentStep = .chooseRelatedEntityorfinish
                } else {
                    currentStep = .selectAttribute
                }
            } else {
                currentStep = .confirmParameter
            }
        case .chooseRelatedEntity:
            if let entity = EntityType(rawValue: selection) {
                print("parametre actuelle : \(String(describing: currentParameter))")

                currentParameter?.relatedEntity = entity
                currentStep = .selectAttribute
            } else {
                print("Entité liée non reconnue : \(selection)")
            }
            
        case .selectAttribute:
            let attributes = getRelevantAttributes()
            if let attribute = attributes.first(where: { $0.displayName == selection }) {
                currentAttribute = attribute
                currentStep = .selectAttributeValue
            }
        case .selectAttributeValue:
            if let attribute = currentAttribute {
                print("parametre actuelle : \(String(describing: currentParameter))")

                // Vérifier si l'attribut permet la sélection multiple
                if allowsMultipleSelection(for: attribute) {
                    // Passer à une méthode pour gérer les sélections multiples
                    currentStep = .waitingForMultipleSelection
                } else {
                    let newSelection = Selection(attribute: attribute, value: .string(selection))
                    currentParameter?.selections.append(newSelection)
                    currentAttribute = nil
                    currentStep = .addFilter
                }
            }
        case .waitingForMultipleSelection:
            // Cette étape sera gérée par la méthode `processMultipleSelections`
            break
        case .addAnotherParameter:
            if selection == "Oui" {
                // Continuer à ajouter des paramètres à la même donnée
                currentStep = .selectEntity
            } else {
                // Si l'utilisateur ne veut pas ajouter d'autre paramètre, enregistrer la donnée complète
                graphConfigurationBuilder.configuredData.append(graphConfigurationBuilder.currentData)
                graphConfigurationBuilder.currentData = ConfiguredData()  // Réinitialiser la donnée en cours
                
                // Afficher les logs des données configurées
                graphConfigurationBuilder.logConfiguredData()
                
                // Passer à l'étape où l'utilisateur peut choisir de configurer une nouvelle donnée ou visualiser
                currentStep = .defineComparison  // Ou une autre étape selon votre logique
            }
            
            
        case .configurePlotOptions:
            if selection.lowercased() == "oui" {
                switch graphConfigurationBuilder.visualizationType {
                case .barChart:
                    currentBarChartOption = .orientation
                case .lineChart:
                    currentLineChartOption = .lineType
                case .pieChart:
                    currentPieChartOption = .holeRadius
                case .scatterPlot:
                    currentScatterPlotOption = .shapeType
                case .radarChart:
                    currentRadarChartOption = .fillEnabled
                case .none:
                    currentStep = .confirmConfiguration
                    return
                }
                currentStep = .configureChartSpecificOptions
            } else {
                currentStep = .confirmConfiguration
            }


      

        
        case .configureChartTitle:
                graphConfigurationBuilder.chartOptions.title = selection
                currentStep = .configureXAxisLabel
            case .configureXAxisLabel:
                graphConfigurationBuilder.chartOptions.xAxisLabel = selection
                currentStep = .configureYAxisLabel
            case .configureYAxisLabel:
                graphConfigurationBuilder.chartOptions.yAxisLabel = selection
                currentStep = .configureLegend
            case .configureLegend:
                graphConfigurationBuilder.chartOptions.legendEnabled = (selection.lowercased() == "oui")
                currentStep = .configureAnimation
            case .configureAnimation:
                graphConfigurationBuilder.chartOptions.animationEnabled = (selection.lowercased() == "oui")
                currentStep = .configureChartSpecificOptions
            case .configureChartSpecificOptions:
                configureChartSpecificOptions(selection)
            if isAllChartOptionsConfigured() {
                currentStep = .confirmConfiguration
            }
        case .confirmParameter:
            if selection == "Confirmer" {
                if let parameter = currentParameter {
                    graphConfigurationBuilder.currentData.parameters.append(parameter)
                    print("Paramètre ajouté : \(parameter)")

                    currentDataIndex += 1
                    
                    if currentDataIndex < requiredDataSets {
                        currentStep = .configureData(requiredDataSets)
                    } else {
                        print("currentData avant ajout à configuredData : \(graphConfigurationBuilder.currentData)")

                        graphConfigurationBuilder.configuredData.append(graphConfigurationBuilder.currentData)
                        graphConfigurationBuilder.currentData = ConfiguredData()
                        // Après avoir ajouté currentData à configuredData
                        graphConfigurationBuilder.logConfiguredData()

                        print("currentData ajouté à configuredData")

                        currentStep = .configurePlotOptions
                    }
                    
                    currentParameter = nil
                }
            } else if selection == "Annuler" {
                currentParameter = nil
                currentStep = .configureData(requiredDataSets)
            }
        case .confirmConfiguration:
            if selection.lowercased() == "confirmer" {
                currentStep = .enterConfigurationName
            } else {
                // Retour à une étape précédente si nécessaire
            }
            
        case .enterConfigurationName:
            graphConfigurationBuilder.name = selection
            finishConfiguration()
        case .end:
            NotificationCenter.default.post(name: .configurationEnded, object: nil)

        default:
            print("Étape non gérée : \(currentStep)")
            
            break
        }
        print("Étape actuelle après traitement : \(currentStep)")
        
    }
    private func isAllChartOptionsConfigured() -> Bool {
        switch graphConfigurationBuilder.visualizationType {
        case .barChart:
            return currentBarChartOption == nil
        case .lineChart:
            return currentLineChartOption == nil
        case .pieChart:
            return currentPieChartOption == nil
        case .scatterPlot:
            return currentScatterPlotOption == nil
        case .radarChart:
            return currentRadarChartOption == nil
        case .none:
            return true
        }
    }

    private func configureChartSpecificOptions(_ selection: String) {
        switch graphConfigurationBuilder.visualizationType {
        case .barChart:
            configureBarChartOptions(selection)
            if currentBarChartOption == nil {
                currentStep = .confirmConfiguration
            }
        case .lineChart:
            configureLineChartOptions(selection)
            if currentLineChartOption == nil {
                currentStep = .confirmConfiguration
            }
        case .pieChart:
            configurePieChartOptions(selection)
            if currentPieChartOption == nil {
                currentStep = .confirmConfiguration
            }
        case .scatterPlot:
            configureScatterPlotOptions(selection)
            if currentScatterPlotOption == nil {
                currentStep = .confirmConfiguration
            }
        case .radarChart:
            configureRadarChartOptions(selection)
            if currentRadarChartOption == nil {
                currentStep = .confirmConfiguration
            }
        case .none:
            currentStep = .confirmConfiguration
        }
    }

    
    private func configureBarChartOptions(_ selection: String) {
        guard let option = currentBarChartOption else {
            return
        }
        
        switch option {
        case .orientation:
            graphConfigurationBuilder.chartOptions.barChartOptions = BarChartOptions(
                isHorizontal: selection.lowercased() == "horizontales",
                groupSpacing: 0.0,  // Valeur par défaut
                showValuesOnBars: false  // Valeur par défaut
            )
            currentBarChartOption = .groupSpacing
        case .groupSpacing:
            if let spacing = Double(selection) {
                graphConfigurationBuilder.chartOptions.barChartOptions?.groupSpacing = spacing
            }
            currentBarChartOption = .showValues
        case .showValues:
            graphConfigurationBuilder.chartOptions.barChartOptions?.showValuesOnBars = (selection.lowercased() == "oui")
            currentBarChartOption = nil  // Toutes les options ont été configurées
        }
    }


    private func configureLineChartOptions(_ selection: String) {
        guard let option = currentLineChartOption else {
            return
        }
        
        switch option {
        case .lineType:
            let lineType: LineType
            switch selection.lowercased() {
            case "droite":
                lineType = .straight
            case "courbe":
                lineType = .curved
            case "escalier":
                lineType = .stepped
            default:
                lineType = .straight  // Valeur par défaut
            }
            graphConfigurationBuilder.chartOptions.lineChartOptions = LineChartOptions(
                lineType: lineType,
                lineWidth: 1.0,       // Valeur par défaut
                fillEnabled: false    // Valeur par défaut
            )
            currentLineChartOption = .lineWidth
        case .lineWidth:
            if let width = Double(selection) {
                graphConfigurationBuilder.chartOptions.lineChartOptions?.lineWidth = CGFloat(width)
            }
            currentLineChartOption = .fillEnabled
        case .fillEnabled:
            graphConfigurationBuilder.chartOptions.lineChartOptions?.fillEnabled = (selection.lowercased() == "oui")
            currentLineChartOption = nil  // Toutes les options ont été configurées
        }
    }


    private func configurePieChartOptions(_ selection: String) {
        guard let option = currentPieChartOption else {
            return
        }
        
        switch option {
        case .holeRadius:
            if let radius = Double(selection) {
                graphConfigurationBuilder.chartOptions.pieChartOptions = PieChartOptions(
                    holeRadius: CGFloat(radius),
                    showPercentages: false  // Valeur par défaut
                )
            }
            currentPieChartOption = .showPercentages
        case .showPercentages:
            graphConfigurationBuilder.chartOptions.pieChartOptions?.showPercentages = (selection.lowercased() == "oui")
            currentPieChartOption = nil  // Toutes les options ont été configurées
        }
    }


    private func configureScatterPlotOptions(_ selection: String) {
        guard let option = currentScatterPlotOption else {
            return
        }
        
        switch option {
        case .shapeType:
            let shapeType: ScatterChartDataSet.Shape
            switch selection.lowercased() {
            case "cercle":
                shapeType = .circle
            case "carré":
                shapeType = .square
            case "triangle":
                shapeType = .triangle
            default:
                shapeType = .circle  // Valeur par défaut
            }
            graphConfigurationBuilder.chartOptions.scatterPlotOptions = ScatterPlotOptions(
                shapeType: shapeType,
                showTrendLine: false  // Valeur par défaut
            )
            currentScatterPlotOption = .showTrendLine
        case .showTrendLine:
            graphConfigurationBuilder.chartOptions.scatterPlotOptions?.showTrendLine = (selection.lowercased() == "oui")
            currentScatterPlotOption = nil  // Toutes les options ont été configurées
        }
    }


    private func configureRadarChartOptions(_ selection: String) {
        guard let option = currentRadarChartOption else {
            return
        }
        
        switch option {
        case .fillEnabled:
            graphConfigurationBuilder.chartOptions.radarChartOptions = RadarChartOptions(
                fillEnabled: (selection.lowercased() == "oui"),
                rotationEnabled: false  // Valeur par défaut
            )
            currentRadarChartOption = .rotationEnabled
        case .rotationEnabled:
            graphConfigurationBuilder.chartOptions.radarChartOptions?.rotationEnabled = (selection.lowercased() == "oui")
            currentRadarChartOption = nil  // Toutes les options ont été configurées
        }
    }

    func finishConfiguration() {
    // Générer la configuration finale
    let config = graphConfigurationBuilder.buildGraphConfiguration()
    
    // Notifier le ChatBotViewController que la configuration est terminée
    NotificationCenter.default.post(name: .configurationFinished, object: config)
    
    currentStep = .end
}
    func getEntityId(_ entity: Any) -> String? {
        switch entity {
        case let fighter as Fighter:
            return fighter.id
        case let event as Event:
            return event.id
        case let fight as Fight:
            return fight.id
        default:
            return nil
        }
    }
    func getRelevantAttributes() -> [Attribute] {
        if let relatedEntity = currentParameter?.relatedEntity {
            return getAttributesForEntity(relatedEntity)
        } else {
            return getAttributesForEntity(currentParameter?.mainEntity ?? .fighter)
        }
    }
    func displayConfiguredData() -> String {
        var message = "Voici la configuration actuelle de vos données : \n"
            print("Nombre de données configurées : \(graphConfigurationBuilder.configuredData.count)")
        for (index, data) in graphConfigurationBuilder.configuredData.enumerated() {
            message += "Donnée \(index + 1) : \n"
            print("Traitement de la donnée \(index + 1)")

            
            for parameter in data.parameters {
                message += "Entité principale : \(parameter.mainEntity.rawValue)\n"
                print("Entité principale : \(parameter.mainEntity.rawValue)")

                if let specificEntityId = parameter.specificEntityId {
                    message += "Entité spécifique : \(specificEntityId)\n"
                }
                if let relatedEntity = parameter.relatedEntity {
                    message += "Entité liée : \(relatedEntity.rawValue)\n"
                }
                message += "Attributs sélectionnés :\n"
                
                for selection in parameter.selections {
                    message += "- \(selection.attribute.displayName) : \(selection.value)\n"
                }
                
                message += "Filtres appliqués :\n"
                for filter in parameter.filters {
                    message += "- \(filter.attribute.displayName) \(filter.operation.rawValue) \(filter.value)\n"
                }
                message += "\n"
            }
            
            message += "-----------------------------------------\n"
        }
        
        return message
    }
    
    
 private func saveConfiguration() {
    guard let config = graphConfigurationBuilder.buildGraphConfiguration() else {
        print("Erreur : Impossible de construire la configuration du graphique")
        return
    }
    
    FirebaseService.shared.saveGraphConfiguration(config) { result in
        switch result {
        case .success:
            NotificationCenter.default.post(name: .configurationSaved, object: nil)
        case .failure(let error):
            NotificationCenter.default.post(name: .configurationSaveFailed, object: error)
        }
    }
}

// Ajoutez ces extensions en dehors de la classe ChatBotManager

    // Méthodes auxiliaires
func getAttributesForEntity(_ entity: EntityType) -> [Attribute] {
    switch entity {
    case .fighter:
        return [.fighter(.country)]  // Seul le pays est pertinent pour l'affinage
    case .fight:
        return [
            .event(.eventType),
            .event(.date),
            .event(.eventName),
            .fight(.category),
            .fight(.weightCategory),
            .fight(.round)
        ]
    case .event:
        return [
            .event(.country),
            .event(.eventName),
            .event(.eventType)
        ]
    case .round:
        return [.round(.roundTime)]
    case .action:
        // Inclure tous les attributs pertinents de 'Action'
        return ActionAttribute.allCases.map { Attribute.action($0) }
    case .category:
        return [.ageCategory(.ageCategory)]
    case .weightCategory:
        return [.weightCategory(.weightCategory)]
    case .gender:
        return [.gender(.gender)]
    case .eventType:
        return [.eventType(.eventType)]
    case .actionType:
        return [.actionType(.actionType)]
    case .actionMoment:
        return []
    }
}
    
    
}

extension Attribute: Equatable {
    static func == (lhs: Attribute, rhs: Attribute) -> Bool {
        switch (lhs, rhs) {
        case (.ageCategory(let a), .ageCategory(let b)):
            return a == b
        case (.gender(let a), .gender(let b)):
            return a == b
        case (.weightCategory(let a), .weightCategory(let b)):
            return a == b
        // Ajoutez d'autres cas pour les autres types d'attributs
        default:
            return false
        }
    }
}
extension Notification.Name {
    static let configurationSaved = Notification.Name("configurationSaved")
    static let configurationSaveFailed = Notification.Name("configurationSaveFailed")
    static let configurationFinished = Notification.Name("configurationFinished")
    static let configurationEnded = Notification.Name("configurationEnded")
}
