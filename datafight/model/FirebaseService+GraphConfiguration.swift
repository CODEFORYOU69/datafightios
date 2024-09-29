import Firebase
import FirebaseFirestore
import FirebaseAuth

extension FirebaseService {
    
    func fetchFilteredFights(
        fighter: String? = nil,
        gender: String? = nil,
        fighterNationality: String? = nil,
        event: String? = nil,
        eventType: String? = nil,
        eventCountry: String? = nil,
        ageCategory: String? = nil,
        weightCategory: String? = nil,
        isOlympic: Bool? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [Fight] {
        
        print("Début de fetchFilteredFights")
        print("Paramètres reçus:")
        print("fighter: \(String(describing: fighter))")
        print("gender: \(String(describing: gender))")
        print("fighterNationality: \(String(describing: fighterNationality))")
        print("event: \(String(describing: event))")
        print("eventType: \(String(describing: eventType))")
        print("eventCountry: \(String(describing: eventCountry))")
        print("ageCategory: \(String(describing: ageCategory))")
        print("weightCategory: \(String(describing: weightCategory))")
        print("isOlympic: \(String(describing: isOlympic))")
        print("startDate: \(String(describing: startDate))")
        print("endDate: \(String(describing: endDate))")
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("Erreur: Aucun utilisateur authentifié")
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        print("Utilisateur actuel ID: \(currentUserId)")
        
        let db = Firestore.firestore()
        var query: Query = db.collection("fights").whereField("creatorUserId", isEqualTo: currentUserId)
        
        if let fighter = fighter {
            print("Ajout du filtre pour le combattant: \(fighter)")
            query = query.whereField("blueFighterId", isEqualTo: fighter).whereField("redFighterId", isEqualTo: fighter)
        }
        
        if let gender = gender {
            print("Ajout du filtre pour le genre: \(gender)")
            query = query.whereField("category", isEqualTo: gender)
        }
        
        if let ageCategory = ageCategory {
            print("Ajout du filtre pour la catégorie d'âge: \(ageCategory)")
            query = query.whereField("category", isEqualTo: ageCategory)
        }
        
        if let weightCategory = weightCategory {
            print("Ajout du filtre pour la catégorie de poids: \(weightCategory)")
            query = query.whereField("weightCategory", isEqualTo: weightCategory)
        }
        
        if let event = event {
            print("Ajout du filtre pour l'événement: \(event)")
            query = query.whereField("eventId", isEqualTo: event)
        }
        
        if let isOlympic = isOlympic {
            print("Ajout du filtre pour isOlympic: \(isOlympic)")
            query = query.whereField("isOlympic", isEqualTo: isOlympic)
        }
        
        // Exécuter la requête
        print("Exécution de la requête Firebase pour les combats")
        let querySnapshot = try await query.getDocuments()
        print("Nombre de documents récupérés: \(querySnapshot.documents.count)")
        
        let fights = querySnapshot.documents.compactMap { document -> Fight? in
            let fight = try? document.data(as: Fight.self)
            if let fight = fight {
                print("Combat récupéré: \(fight)")
            } else {
                print("Impossible de convertir le document en Fight pour le document ID: \(document.documentID)")
            }
            return fight
        }
        
        // Récupérer les IDs des événements et des combattants liés
        let eventIds = Set(fights.map { $0.eventId })
        let fighterIds = Set(fights.flatMap { [$0.blueFighterId, $0.redFighterId] })
        
        print("IDs des événements à récupérer: \(eventIds)")
        print("IDs des combattants à récupérer: \(fighterIds)")
        
        // Récupérer les événements
        var events: [Event] = []
        try await withCheckedThrowingContinuation { continuation in
            fetchEvents(withIds: Array(eventIds)) { result in
                switch result {
                case .success(let fetchedEvents):
                    events = fetchedEvents
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        print("Nombre d'événements récupérés: \(events.count)")
        
        // Récupérer les combattants
        let fighters = try await fetchFighters(ids: Array(fighterIds))
        print("Nombre de combattants récupérés: \(fighters.count)")
        
        // Filtrage côté client
        let filteredFights = fights.filter { fight in
            var include = true
            
            if let event = events.first(where: { $0.id == fight.eventId }) {
                print("Traitement de l'événement pour le combat ID: \(fight.id ?? "Inconnu")")
                
                // Filtrage par date
                if let startDate = startDate, let endDate = endDate {
                    include = include && (event.date >= startDate && event.date <= endDate)
                    print("Filtrage par date pour l'événement ID: \(event.id ?? "Inconnu"), inclure: \(include)")
                }
                
                // Filtrage par type d'événement
                if let eventType = eventType {
                    include = include && (event.eventType.rawValue == eventType)
                    print("Filtrage par type d'événement pour l'événement ID: \(event.id ?? "Inconnu"), inclure: \(include)")
                }
                
                // Filtrage par pays de l'événement
                if let eventCountry = eventCountry {
                    include = include && (event.country == eventCountry)
                    print("Filtrage par pays pour l'événement ID: \(event.id ?? "Inconnu"), inclure: \(include)")
                }
            } else {
                print("Événement non trouvé pour le combat ID: \(fight.id ?? "Inconnu")")
                include = false
            }
            
            // Filtrage par nationalité du combattant
            if let fighterNationality = fighterNationality {
                let blueFighter = fighters.first(where: { $0.id == fight.blueFighterId })
                let redFighter = fighters.first(where: { $0.id == fight.redFighterId })
                
                let blueFighterMatch = blueFighter?.country == fighterNationality
                let redFighterMatch = redFighter?.country == fighterNationality
                include = include && (blueFighterMatch || redFighterMatch)
                print("Filtrage par nationalité pour le combat ID: \(fight.id ?? "Inconnu"), inclure: \(include)")
            }
            
            return include
        }
        
        print("Nombre de combats après filtrage: \(filteredFights.count)")
        return filteredFights
    }
    
    func fetchRounds(for fight: Fight) async throws -> [Round] {
        print("Début de fetchRounds pour le combat ID: \(fight.id ?? "Inconnu")")
        
        guard let roundIds = fight.roundIds else {
            print("Aucun roundId trouvé pour le combat ID: \(fight.id ?? "Inconnu")")
            return []
        }
        
        print("IDs des rounds à récupérer: \(roundIds)")
        
        let db = Firestore.firestore()
        return try await withThrowingTaskGroup(of: Round?.self) { group in
            for roundId in roundIds {
                group.addTask {
                    print("Récupération du round ID: \(roundId)")
                    let documentSnapshot = try await db.collection("rounds").document(roundId).getDocument()
                    let round = try? documentSnapshot.data(as: Round.self)
                    if let round = round {
                        print("Round récupéré: \(round)")
                    } else {
                        print("Impossible de convertir le document en Round pour le document ID: \(roundId)")
                    }
                    return round
                }
            }
            
            var fetchedRounds: [Round] = []
            for try await round in group {
                if let round = round {
                    fetchedRounds.append(round)
                }
            }
            print("Nombre de rounds récupérés: \(fetchedRounds.count)")
            return fetchedRounds
        }
    }
    
func fetchEvents(withIds ids: [String], completion: @escaping (Result<[Event], Error>) -> Void) {
    
    guard !ids.isEmpty else {
        // Return an empty array since there are no IDs to query
        completion(.success([]))
        return
    }
    let db = Firestore.firestore()
    let eventsRef = db.collection("events")
    
    eventsRef.whereField(FieldPath.documentID(), in: ids).getDocuments { (querySnapshot, error) in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let documents = querySnapshot?.documents else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No documents found"])))
            return
        }
        
        let events = documents.compactMap { document -> Event? in
            var event = try? document.data(as: Event.self)
            event?.id = document.documentID  // Assurez-vous que l'ID est correctement défini
            return event
        }
        
        completion(.success(events))
    }
}
    
     func fetchFighters(ids: [String]) async throws -> [Fighter] {
        print("Début de fetchFighters avec IDs: \(ids)")
        guard !ids.isEmpty else {
             print("Aucun ID de combattant fourni. Retourne un tableau vide.")
             return []
         }
        let db = Firestore.firestore()
        let querySnapshot = try await db.collection("fighters").whereField(FieldPath.documentID(), in: ids).getDocuments()
        print("Nombre de documents combattants récupérés: \(querySnapshot.documents.count)")
        
        let fighters = querySnapshot.documents.compactMap { document -> Fighter? in
            let fighter = try? document.data(as: Fighter.self)
            if let fighter = fighter {
                print("Combattant récupéré: \(fighter)")
            } else {
                print("Impossible de convertir le document en Fighter pour le document ID: \(document.documentID)")
            }
            return fighter
        }
        
        return fighters
    }
}
