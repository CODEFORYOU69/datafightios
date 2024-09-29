//
//  FirebaseService+Event.swift .swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

// FirebaseService+Event.swift

import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit
import FirebaseAuth



extension FirebaseService {
    // MARK: - Event Methods
    func updateEventWithFight(eventId: String, fightId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let eventRef = db.collection("events").document(eventId)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let eventDocument: DocumentSnapshot
            do {
                try eventDocument = transaction.getDocument(eventRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard var event = try? eventDocument.data(as: Event.self) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch event"])
                errorPointer?.pointee = error
                return nil
            }

            event.fightIds = (event.fightIds ?? []) + [fightId]
            
            do {
                try transaction.setData(from: event, forDocument: eventRef)
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
    func saveEvent(_ event: Event, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        if let id = event.id {
            do {
                try db.collection("events").document(id).setData(from: event) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(id))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        } else {
            let newDocRef = db.collection("events").document()
            var newEvent = event
            newEvent.creatorUserId = uid  // Ensure creatorUserId is set to current authenticated user
            
            newEvent.id = newDocRef.documentID
            do {
                try newDocRef.setData(from: newEvent) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(newDocRef.documentID))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }


    func getEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        db.collection("events")
            .whereField("creatorUserId", isEqualTo: uid)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let events = querySnapshot?.documents.compactMap { document -> Event? in
                        var event = try? document.data(as: Event.self)
                        event?.id = document.documentID
                        return event
                    } ?? []
                    completion(.success(events))
                }
            }
    }

    func getEvent(id: String, completion: @escaping (Result<Event, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        db.collection("events").document(id).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                do {
                    var event = try document.data(as: Event.self)
                    if event.creatorUserId == uid {
                        event.id = document.documentID
                        completion(.success(event))
                    } else {
                        completion(.failure(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unauthorized access"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Event not found"])))
            }
        }
    }


    func uploadEventImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get image data"])))
            return
        }

        let imageName = UUID().uuidString
        let imageRef = storage.child("event_images/\(imageName).jpg")

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

   
}

extension FirebaseService {
    func saveEventAsync(_ event: Event) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            saveEvent(event) { result in
                switch result {
                case .success(let eventId):
                    continuation.resume(returning: eventId)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    func fetchEventsAsync(withIds ids: [String]) async throws -> [Event] {
            try await withCheckedThrowingContinuation { continuation in
                fetchEvents(withIds: ids) { result in
                    switch result {
                    case .success(let events):
                        continuation.resume(returning: events)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
}
