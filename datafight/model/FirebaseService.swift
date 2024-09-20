// FirebaseService.swift

import Firebase
import FirebaseFirestore

import FirebaseStorage
import UIKit
import FirebaseAuth
import Network
import FirebaseFirestoreCombineSwift

class FirebaseService {
    static let shared = FirebaseService()
    let db = Firestore.firestore()
    let storage = Storage.storage().reference()
    let monitor = NWPathMonitor()
    var isConnected = true

    private init() {
        startNetworkMonitoring()
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            if self?.isConnected == true {
                self?.syncUnsyncedData()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

   
    private func syncUnsyncedData() {
        syncCachedRounds { result in
            switch result {
            case .success:
                print("Successfully synced cached rounds")
            case .failure(let error):
                print("Failed to sync cached rounds: \(error.localizedDescription)")
            }
        }
    }
    func syncCachedRounds(completion: @escaping (Result<Void, Error>) -> Void) {
        let unsyncedRounds = CoreDataManager.shared.getUnsyncedRounds()
        let group = DispatchGroup()

        for round in unsyncedRounds {
            group.enter()
            if let fight = CoreDataManager.shared.getFightForRound(round) {
                saveRound(round, for: fight) { result in
                    switch result {
                    case .success:
                        CoreDataManager.shared.markRoundAsSynced(id: round.id!, for: fight)
                    case .failure(let error):
                        print("Failed to sync round: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            } else {
                print("Failed to find fight for round: \(round.id ?? "unknown")")
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(.success(()))
        }
    }
    func getCurrentUserID() -> Result<String, Error> {
        if let uid = Auth.auth().currentUser?.uid {
            return .success(uid)
        } else {
            return .failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
        }
    }

    func fetchEntities<T: Codable>(ofType type: T.Type, from collection: String, filters: [Filter], completion: @escaping (Result<[T], Error>) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                return
            }

            var query: Query = db.collection(collection).whereField("creatorUserId", isEqualTo: userId)

            for filter in filters {
                query = applyFilter(query: query, filter: filter)
            }

            query.getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let entities = snapshot?.documents.compactMap { document -> T? in
                        do {
                            let entity = try document.data(as: T.self)
                            return entity
                        } catch {
                            print("Erreur lors du décodage de \(T.self): \(error)")
                            return nil
                        }
                    } ?? []
                    completion(.success(entities))
                }
            }
        }

        // Assurez-vous que la fonction `applyFilter` est correctement définie
        private func applyFilter(query: Query, filter: Filter) -> Query {
            switch filter.operation {
            case .equalTo:
                return query.whereField(filter.field, isEqualTo: filter.value)
            case .notEqualTo:
                return query.whereField(filter.field, isNotEqualTo: filter.value)
            case .greaterThan:
                return query.whereField(filter.field, isGreaterThan: filter.value)
            case .lessThan:
                return query.whereField(filter.field, isLessThan: filter.value)
            case .contains:
                return query.whereField(filter.field, arrayContains: filter.value)
            }
        }

    
}

// Extensions pour l'encodage/décodage des objets
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "FirebaseService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to convert object to dictionary"])
        }
        return dictionary
    }
}


