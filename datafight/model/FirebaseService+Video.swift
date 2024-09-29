//
//  FirebaseService+Video.swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

// FirebaseService+Video.swift

import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit
import FirebaseAuth
import AVFoundation

extension FirebaseService {
    // MARK: - Video Methods

    func uploadVideo(for fight: Fight, videoURL: URL, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<Video, Error>) -> Void) {
        let videoId = UUID().uuidString
           let storageRef = storage.child("videos/\(videoId).mp4")
           
           let fileManager = FileManager.default
           let tempDirectoryURL = fileManager.temporaryDirectory
           let tempFileURL = tempDirectoryURL.appendingPathComponent(videoId).appendingPathExtension("mp4")
           
           do {
               try fileManager.copyItem(at: videoURL, to: tempFileURL)
               
               guard fileManager.fileExists(atPath: tempFileURL.path) else {
                   completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Temp video file does not exist"])))
                   return
               }
               
               let videoData = try Data(contentsOf: tempFileURL)

            // Début de l'upload
            let uploadTask = storageRef.putData(videoData, metadata: nil)

            // Suivi de la progression
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentage = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    progressHandler(percentage)
                }
            }

            // Gestion de l'achèvement de l'upload
            uploadTask.observe(.success) { snapshot in
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    guard let downloadURL = url else {
                        completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                        return
                    }

                    // Récupérer la durée de la vidéo
                    let asset = AVAsset(url: videoURL)
                    Task {
                        do {
                            let duration = try await asset.load(.duration)
                            let durationInSeconds = CMTimeGetSeconds(duration)

                            let video = Video(
                                id: videoId,
                                fightId: fight.id ?? "",
                                url: downloadURL.absoluteString,
                                duration: durationInSeconds,
                                roundTimestamps: []
                            )

                            try await self.db.collection("videos").document(videoId).setData(video.dictionary)
                            try await self.db.collection("fights").document(fight.id ?? "").updateData([
                                "videoId": videoId,
                                "videoURL": downloadURL.absoluteString
                            ])
                            completion(.success(video))

                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
            }

            // Gestion de l'échec de l'upload
               uploadTask.observe(.failure) { snapshot in
                   if let error = snapshot.error as NSError? {
                       print("Upload failed with error: \(error.localizedDescription)")
                       print("Error code: \(error.code)")
                       completion(.failure(error))
                   }
               }
        } catch {
            completion(.failure(error))
        }
    }

    func getVideo(by videoId: String, completion: @escaping (Result<Video, Error>) -> Void) {
        guard !videoId.isEmpty else {
            completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Video ID is empty"])))
            return
        }

        let docRef = db.collection("videos").document(videoId)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                guard let data = document.data() else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data found for video"])))
                    return
                }
                // Utilisation de l'initialiseur personnalisé pour créer l'objet Video
                if let video = Video(dictionary: data) {
                    completion(.success(video))
                } else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse video data"])))
                }
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Video not found"])))
            }
        }
    }
    
    func updateVideoTimestamps(videoId: String, roundNumber: Int, startTimestamp: TimeInterval, endTimestamp: TimeInterval?, completion: @escaping (Result<Void, Error>) -> Void) {
        let videoRef = db.collection("videos").document(videoId)
        
        videoRef.getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(.failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Video not found"])))
                return
            }
            
            do {
                var video = try Firestore.Decoder().decode(Video.self, from: data)
                
                // Update or add the round timestamp
                video.updateOrAddRoundTimestamp(roundNumber: roundNumber, start: startTimestamp, end: endTimestamp)
                
                // Encode the updated video object
                let updatedData = try Firestore.Encoder().encode(video)
                
                // Update the video document
                videoRef.setData(updatedData, merge: true) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    func updateVideo(_ video: Video, completion: @escaping (Result<Void, Error>) -> Void) {
        let videoId = video.id


        do {
            try db.collection("videos").document(videoId).setData(from: video) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func updateVideoRoundTimestamps(for fight: Fight, roundNumber: Int, startTime: TimeInterval, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let fightId = fight.id else {
            completion(.failure(NSError(domain: "FightError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Fight ID is missing"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Rechercher le document de la vidéo associée à ce combat
        db.collection("videos").whereField("fightId", isEqualTo: fightId).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching video: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                let noVideoError = NSError(domain: "VideoError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No video found for this fight"])
                print(noVideoError.localizedDescription)
                completion(.failure(noVideoError))
                return
            }
            
            print("Video document found: \(document.documentID)")

            // Nouveau timestamp de round
            let newRoundTimestamp: [String: Any] = [
                "roundNumber": roundNumber,
                "start": startTime,
                "end": NSNull()
            ]
            
            // Mise à jour du document vidéo dans Firestore
            document.reference.updateData([
                "roundTimestamps": FieldValue.arrayUnion([newRoundTimestamp])
            ]) { error in
                if let error = error {
                    print("Error updating round timestamps: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Successfully updated round timestamps")
                    completion(.success(()))
                }
            }
        }
    }

}
