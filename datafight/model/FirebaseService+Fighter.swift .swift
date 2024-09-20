    //
    //  FirebaseService+Fighter.swift .swift
    //  datafight
    //
    //  Created by younes ouasmi on 14/09/2024.
    //


        import Firebase
        import FirebaseFirestore
        import FirebaseStorage
        import UIKit
        import FirebaseAuth

    extension FirebaseService {
        // MARK: - Fighter Methods

        func saveFighter(_ fighter: Fighter, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let uid = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                return
            }

            var fighterData = fighter
            fighterData.creatorUserId = uid  // Assurez-vous que l'ID de l'utilisateur est défini

            do {
                // Utilisation de `try` car `addDocument(from:)` peut lancer une erreur
                try db.collection("fighters").addDocument(from: fighterData) { error in
                    if let error = error {
                        completion(.failure(error))  // En cas d'erreur, renvoyez-la dans le completion handler
                    } else {
                        completion(.success(()))  // Si succès, renvoyez un succès
                    }
                }
            } catch {
                // Gérer l'erreur si l'appel `addDocument(from:)` échoue
                completion(.failure(error))
            }
        }


        func getFighters(completion: @escaping (Result<[Fighter], Error>) -> Void) {
            guard let uid = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                return
            }

            db.collection("fighters")
                .whereField("creatorUserId", isEqualTo: uid)
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        let fighters = querySnapshot?.documents.compactMap { document -> Fighter? in
                            var fighter = try? document.data(as: Fighter.self)
                            fighter?.id = document.documentID  // Assigner l'ID du document à l'objet Fighter
                            return fighter
                        } ?? []
                        completion(.success(fighters))
                    }
                }
        }

        func getFighter(id: String, completion: @escaping (Result<Fighter, Error>) -> Void) {
            db.collection("fighters").document(id).getDocument { (document, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let document = document, document.exists {
                    do {
                        var fighter = try document.data(as: Fighter.self)
                        fighter.id = document.documentID
                        completion(.success(fighter))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fighter not found"])))
                }
            }
        }

        func uploadFighterImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get image data"])))
                return
            }

            let imageName = UUID().uuidString
            let imageRef = storage.child("fighter_images/\(imageName).jpg")

            imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    imageRef.downloadURL { (url, error) in
                        if let url = url {
                            completion(.success(url))
                        } else if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                        }
                    }
                }
            }
        }
        func updateFighterWithFight(fighterId: String, fightId: String, completion: @escaping (Result<Void, Error>) -> Void) {
            let fighterRef = db.collection("fighters").document(fighterId)
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let fighterDocument: DocumentSnapshot
                do {
                    try fighterDocument = transaction.getDocument(fighterRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard var fighter = try? fighterDocument.data(as: Fighter.self) else {
                    let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch fighter"])
                    errorPointer?.pointee = error
                    return nil
                }

                fighter.fightIds = (fighter.fightIds ?? []) + [fightId]
                
                do {
                    try transaction.setData(from: fighter, forDocument: fighterRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                return nil
            }) { (object, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
        // Fonction pour le chatbot: Récupérer les valeurs distinctes des attributs des combattants
        func fetchDistinctFighterValues(for field: String, completion: @escaping (Result<[String], Error>) -> Void) {
            guard let uid = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                return
            }

            db.collection("fighters")
                .whereField("creatorUserId", isEqualTo: uid)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        completion(.failure(error))
                    } else if let snapshot = snapshot {
                        var valuesSet = Set<String>()
                        for document in snapshot.documents {
                            if let value = document.data()[field] as? String {
                                valuesSet.insert(value)
                            }
                        }
                        completion(.success(Array(valuesSet)))
                    } else {
                        completion(.success([]))
                    }
                }
        }
    }
