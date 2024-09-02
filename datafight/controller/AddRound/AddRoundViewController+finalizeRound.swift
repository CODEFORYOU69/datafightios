//
//  AddRoundViewController+finalizeRound.swift
//  datafight
//
//  Created by younes ouasmi on 28/08/2024.
//

import UIKit
import MobileCoreServices
import CoreMedia



extension AddRoundViewController {
   

    func endRound() {
            guard var currentRound = currentRound, let fight = fight else {
                showAlert(title: "Error", message: "No active round or fight")
                return
            }

            pauseTimer()
            pauseVideo()

            // Obtenir le timestamp de fin du round
            let endTimestamp = videoPlayerView.player?.currentTime().seconds ?? 0

            // Demander si le round s'est terminé par expiration du temps
            requestRoundEndReason { [weak self] isEndedByTime in
                guard let self = self else { return }

                // Demander le nombre de hits
                self.requestHitsCount { blueHits, redHits in
                    // Mettre à jour le round actuel avec les informations finales
                    currentRound.duration = self.chronoDuration - self.remainingTime
                    currentRound.chronoDuration = self.chronoDuration // Assurez-vous que chronoDuration                    currentRound.blueHits = blueHits
                    currentRound.redHits = redHits

                    // Déterminer le vainqueur et la décision
                    let (winner, decision) = currentRound.determineWinner(isEndedByTime: isEndedByTime)

                    // Mettre à jour le round avec le résultat
                    currentRound.roundWinner = winner?.rawValue == "blue" ? fight.blueFighterId : fight.redFighterId
                    currentRound.victoryDecision = decision

                    // Afficher le récapitulatif du round
                    self.showRoundSummary(round: currentRound, winner: winner) {
                        // Sauvegarder le round dans Firebase
                        self.saveRoundToFirebase(currentRound, endTimestamp: endTimestamp)
                    }
                }
            }
        }

        func requestRoundEndReason(completion: @escaping (Bool) -> Void) {
            let alertController = UIAlertController(title: "End of Round", message: "Did the round end by time expiration?", preferredStyle: .alert)

            let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                completion(true)
            }
            let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
                completion(false)
            }

            alertController.addAction(yesAction)
            alertController.addAction(noAction)

            present(alertController, animated: true, completion: nil)
        }
    

    func showRoundSummary(round: Round, winner: FighterColor?, completion: @escaping () -> Void) {
        let winnerText = winner.map { $0.rawValue.capitalized } ?? "No winner (Referee decision)"
        let message = """
        Blue Score: \(round.blueScore)
        Red Score: \(round.redScore)
        Blue Gamjeons: \(round.blueGamJeon)
        Red Gamjeons: \(round.redGamJeon)
        Blue Hits: \(round.blueHits)
        Red Hits: \(round.redHits)
        Winner: \(winnerText)
        Decision: \(round.victoryDecision?.rawValue ?? "N/A")
        """

        let alertController = UIAlertController(title: "Round Summary", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion()
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    func saveRoundToFirebase(_ round: Round, endTimestamp: TimeInterval) {
        guard let fight = fight else { return }

        var updatedRound = round
        updatedRound.chronoDuration = self.chronoDuration

        FirebaseService.shared.saveRoundAndUpdateFight(updatedRound, for: fight) { [weak self] result in
            switch result {
            case .success(let roundId):
                print("Round saved successfully with ID: \(roundId)")
                self?.updateVideoTimestamps(endTimestamp: endTimestamp)
                
                // Check if the fight is now completed
                if let fightResult = fight.fightResult {
                    self?.showFightCompletionAlert(result: fightResult)
                }
            case .failure(let error):
                self?.showAlert(title: "Error", message: "Failed to save round: \(error.localizedDescription)")
            }
        }
    }

    func showFightCompletionAlert(result: FightResult) {
        let message = "Fight completed. Winner: \(result.winner), Method: \(result.method)"
        let alertController = UIAlertController(title: "Fight Completed", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

        func updateVideoTimestamps(endTimestamp: TimeInterval) {
            guard let fight = fight, let videoId = fight.videoId, let currentRound = currentRound else { return }

            FirebaseService.shared.updateVideoTimestamps(videoId: videoId,
                                                         roundNumber: currentRound.roundNumber,
                                                         startTimestamp: currentRound.chronoDuration - currentRound.duration,
                                                         endTimestamp: endTimestamp) { [weak self] result in
                switch result {
                case .success:
                    print("Video timestamps updated successfully")
                    self?.prepareNextRound(previousEndTimestamp: endTimestamp)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: "Failed to update video timestamps: \(error.localizedDescription)")
                }
            }
        }
    func prepareNextRound(previousEndTimestamp: TimeInterval) {
        guard let fight = fight else { return }
        
        let nextRoundNumber = (currentRound?.roundNumber ?? 0) + 1
        
        // Calculer la nouvelle chronoDuration
        let totalVideoDuration = videoPlayerView.player?.currentItem?.duration.seconds ?? 0
        let newChronoDuration = totalVideoDuration - previousEndTimestamp
        
        // Créer un nouveau round en utilisant le timestamp de fin du round précédent comme début
        let newRound = Round(
            fightId: fight.id ?? "",
            roundNumber: nextRoundNumber,
            chronoDuration: newChronoDuration,
            duration: 0,
            roundTime: currentRound?.roundTime ?? 120, // Utiliser la même durée que le round précédent ou une valeur par défaut
            blueFighterId: fight.blueFighterId,
            redFighterId: fight.redFighterId,
            actions: [],
            videoReplays: [],
            isSynced: false
        )
        
        currentRound = newRound
        
        // Réinitialiser le timer et les scores
        chronoDuration = newChronoDuration
        remainingTime = newChronoDuration
        resetScores()
        updateUI()
        pauseTimer() // Assurez-vous que le timer est arrêté

        
        // Positionner la vidéo au début du nouveau round
        seekVideo(to: CMTime(seconds: previousEndTimestamp, preferredTimescale: 600))
        
        // Afficher une alerte pour informer que le nouveau round est prêt à commencer
        let alertController = UIAlertController(title: "New Round", message: "Round \(nextRoundNumber) is ready to start.", preferredStyle: .alert)
        let startAction = UIAlertAction(title: "Start", style: .default) { [weak self] _ in
            self?.startTimer()
            self?.playVideo()
        }
        alertController.addAction(startAction)
        
        present(alertController, animated: true, completion: nil)
    }
   
    func requestHitsCount(completion: @escaping (Int, Int) -> Void) {
        let alertController = UIAlertController(title: "Hits Count", message: "Enter the number of hits for each fighter", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "Blue Fighter Hits"
            textField.keyboardType = .numberPad
        }
        alertController.addTextField { textField in
            textField.placeholder = "Red Fighter Hits"
            textField.keyboardType = .numberPad
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak alertController] _ in
            guard let textFields = alertController?.textFields,
                  let blueHitsText = textFields[0].text,
                  let redHitsText = textFields[1].text,
                  let blueHits = Int(blueHitsText),
                  let redHits = Int(redHitsText) else {
                completion(0, 0)
                return
            }
            completion(blueHits, redHits)
        }

        alertController.addAction(submitAction)
        present(alertController, animated: true, completion: nil)
    }
}


