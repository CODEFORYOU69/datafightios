//
//  chatbotModel.swift
//  datafight
//
//  Created by younes ouasmi on 13/09/2024.
//

import Foundation

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

    enum ConversationStep {
        case selectVisualizationType
        case selectEntity
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
        case preview
        case end
    }


    var currentStep: ConversationStep = .selectVisualizationType
    var graphConfigurationBuilder = GraphConfigurationBuilder()
    var currentParameter: AnalysisParameter?
    var requiredDataSets: Int = 1

    var currentAttribute: Attribute?
    var currentSelection: Selection?

    func getBotMessage() -> String {
        switch currentStep {
        case .selectVisualizationType:
                    return "Quel type de graphique souhaitez-vous créer ?"
        case .selectEntity:
            return "Que souhaitez-vous analyser ?"
        case .chooseParameterAction:
            return "Voulez-vous sélectionner un \(currentParameter?.entity.rawValue ?? "élément") spécifique ou affiner ce paramètre ?"
        case .selectAttribute:
            return "Quel attribut souhaitez-vous spécifier ?"
        case .selectAttributeValue:
            return "Veuillez choisir une valeur pour l'attribut."
        case .addFilter:
               return "Voulez-vous ajouter un filtre à cette donnée ?"
        case .confirmParameter:
               // Ajout de la configuration actuelle dans le message du bot
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
            return "Choose a specific entity"
        case .addAnotherParameter:
            return " voulez vous  ajouter un nouveau parametre"
        case .waitingForMultipleSelection:
            return "selectionner une ou plusieurs valeurs"
        }
    }

    func getOptions(completion: @escaping ([String]) -> Void) {
        switch currentStep {
        case .selectEntity:
            print("Étape actuelle : \(currentStep)")

            completion(EntityType.allCases.map { $0.rawValue })
        case .chooseParameterAction:
            print("Étape actuelle : \(currentStep)")

            if let entityName = currentParameter?.entity.rawValue {
                print("Nom de l'entité : \(entityName)")

                completion(["Sélectionner un \(entityName)", "Affiner le paramètre"])
            } else {
                print("currentParameter?.entity est nil")

                completion([])
            }
        
        case .confirmParameter:
            completion(["Confirmer", "Annuler"])
        case .addAnotherParameter:
                completion(["Oui", "Non"])

        case .selectAttribute:
            if let entity = currentParameter?.entity {
                let attributes = getAttributesForEntity(entity).map { $0.displayName }
                completion(attributes)
            } else {
                completion([])
            }
        case .selectSpecificEntity:
            if let entity = currentParameter?.entity {
                fetchEntityNames(for: entity) { entityNames in
                    completion(entityNames)
                }
            } else {
                completion([])
            }
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
        case .end:
            completion(["Créer une nouvelle analyse", "Visualiser les résultats", "Retourner au menu principal"])
        default:
            completion([])
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
            // Adapter en fonction de votre logique
            let allWeightCategories = FightCategories.weightCategories.values.flatMap { $0.values.flatMap { $0.values.flatMap { $0 } } }
            completion(allWeightCategories)
        case .gender:
            completion(["men", "women"])
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
                           requiredDataSets = getRequiredDataSets(for: visualizationType)
                           currentStep = .selectEntity
                       }
            case .selectEntity:
                print("Traitement de la sélection d'entité")
                if let entity = EntityType(rawValue: selection) {
                    print("Entité sélectionnée : \(entity)")
                    currentParameter = AnalysisParameter(entity: entity, selections: [], filters: [])
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
            case .chooseParameterAction:
                print("Traitement du choix d'action sur le paramètre")
                if selection.starts(with: "Sélectionner un") {
                    print("Passage à la sélection d'entité spécifique")
                    currentStep = .selectSpecificEntity
                } else if selection == "Affiner le paramètre" {
                    print("Passage au raffinage du paramètre")
                    currentStep = .selectAttribute
                }
        case .selectSpecificEntity:
                if let entityType = currentParameter?.entity {
                      print("EntityType in selectSpecificEntity: \(entityType.rawValue)")
                      if let selectedEntity = availableEntities[selection] {
                          print("Selected entity: \(selectedEntity)")
                          let attribute: Attribute
                          let selectionValue: SelectionValue
                          switch entityType {
                          case .fighter:
                              print("Processing fighter entity")
                              attribute = .fighter(.id)
                              if let fighter = selectedEntity as? Fighter {
                                  print("Fighter ID: \(fighter.id ?? "nil")")
                                  if let id = fighter.id {
                                      selectionValue = .string(id)
                                  } else {
                                      print("Fighter ID is nil")
                                      return
                                  }
                              } else {
                                  print("Failed to cast selectedEntity to Fighter")
                                  return
                              }
                       case .event:
                           attribute = .event(.id)
                           if let event = selectedEntity as? Event, let id = event.id {
                               selectionValue = .string(id)
                           } else {
                               // Gérer l'erreur si nécessaire
                               return
                           }
                       case .fight:
                           attribute = .fight(.id)
                           if let fight = selectedEntity as? Fight, let id = fight.id {
                               selectionValue = .string(id)
                           } else {
                               // Gérer l'erreur si nécessaire
                               return
                           }
                       default:
                           return
                       }
                       let newSelection = Selection(attribute: attribute, value: selectionValue)
                       currentParameter?.selections.append(newSelection)
                       currentStep = .addFilter
                   } else {
                       // Gérer le cas où la sélection n'est pas trouvée
                       print("Entité non trouvée pour la sélection : \(selection)")
                   }
               }

        case .addFilter:
                   if selection == "Oui" {
                       currentStep = .selectAttribute
                   } else {
                       currentStep = .confirmParameter
                   }
        case .selectAttribute:
            if let entity = currentParameter?.entity {
                let attributes = getAttributesForEntity(entity)
                if let attribute = attributes.first(where: { $0.displayName == selection }) {
                    currentAttribute = attribute
                    currentStep = .selectAttributeValue
                }
            }
        case .selectAttributeValue:
               if let attribute = currentAttribute {
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
            case .confirmParameter:
                if selection == "Confirmer" {
                    if let parameter = currentParameter {
                        // Ajouter le paramètre à la donnée en cours de configuration
                        graphConfigurationBuilder.currentData.parameters.append(parameter)
                        // Ajouter la donnée configurée à la liste des données configurées
                        graphConfigurationBuilder.configuredData.append(graphConfigurationBuilder.currentData)
                        
                        
                        // Afficher les logs des données configurées
                        graphConfigurationBuilder.logConfiguredData()

                        // Passer à l'étape d'ajout d'un autre paramètre
                        // Réinitialiser currentData pour la prochaine configuration
                        currentParameter = nil
                        currentStep = .addAnotherParameter
                    }
                } else if selection == "Annuler" {
                    // Réinitialiser et revenir à la sélection de l'entité
                    currentParameter = nil
                    currentStep = .selectEntity
                }
        case .enterConfigurationName:
                graphConfigurationBuilder.name = selection
                saveConfiguration()
                currentStep = .end
        default:
                print("Étape non gérée : \(currentStep)")

            break
        }
        print("Étape actuelle après traitement : \(currentStep)")

    }
    func displayConfiguredData() -> String {
        var message = "Voici la configuration actuelle de vos données : \n"
        
        for (index, data) in graphConfigurationBuilder.configuredData.enumerated() {
            message += "Donnée \(index + 1) : \n"
            
            for parameter in data.parameters {
                message += "Entité : \(parameter.entity.rawValue)\n"
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
          // Implémentez la logique pour sauvegarder la configuration dans Firebase
          // Vous pouvez utiliser FirebaseService.shared.saveGraphConfiguration ici
      }
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
        case .ageCategory, .weightCategory, .gender, .eventType, .actionType:
            return []  // Pas d'attributs supplémentaires
        case .actionMoment:
            return []
        }
    }


}


