import Firebase
import FirebaseFirestore
import FirebaseAuth

extension FirebaseService {
    // MARK: - GraphConfiguration Methods

    func saveGraphConfiguration(_ config: GraphConfiguration, completion: @escaping (Result<Void, Error>) -> Void) {
        var configToSave = config
        if let uid = Auth.auth().currentUser?.uid {
            configToSave.userId = uid
        } else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        do {
            if let id = configToSave.id {
                try db.collection("graphConfigurations").document(id).setData(from: configToSave) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                let newDocRef = db.collection("graphConfigurations").document()
                configToSave.id = newDocRef.documentID
                try newDocRef.setData(from: configToSave) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func getGraphConfigurations(completion: @escaping (Result<[GraphConfiguration], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        db.collection("graphConfigurations")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let snapshot = snapshot {
                    let configurations = snapshot.documents.compactMap { document -> GraphConfiguration? in
                        try? document.data(as: GraphConfiguration.self)
                    }
                    completion(.success(configurations))
                } else {
                    completion(.success([]))
                }
            }
    }

    func deleteGraphConfiguration(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("graphConfigurations").document(id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
