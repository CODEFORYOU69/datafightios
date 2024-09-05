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
        
        
        func setCurrentRoundNumber() {
            guard let fight = fight else {
                currentRoundNumber = 1
                return
            }
            
            currentRoundNumber = (fight.roundIds?.count ?? 0) + 1
            print("Current round number set to: \(currentRoundNumber)")
        }
        func checkRoundEndConditions(_ action: Action) {
            // Vérifiez si l'action entraîne la fin du round
            if action.actionType == .gamJeon && (countGamjeons(for: .blue) >= 5 || countGamjeons(for: .red) >= 5) {
                endRound(with: .punitiveDeclaration)
            } else if abs(calculateScore(for: .blue) - calculateScore(for: .red)) >= 12 {
                endRound(with: .pointGap)
            }
            // Vous pouvez ajouter d'autres conditions ici si nécessaire
        }
        
        func endRound(with decision: VictoryDecision? = nil) {
            guard var round = currentRound else { return }
            
            // Mettre à jour la durée du round
            round.duration = chronoDuration - remainingTime
            
            // Définir la décision de victoire
            round.victoryDecision = decision
            
            // Déterminer le vainqueur du round
            round.determineRoundWinner()
            
            // Sauvegarder le round
            saveRoundData(round)
            
            // Réinitialiser pour le prochain round
            currentRound = nil
            resetTimer()
            resetScores()
        }

        // End the current round
        func endRound() {
            guard var currentRound = currentRound, let fight = fight else {
                showAlert(title: "Error", message: "No active round or fight")
                return
            }

            // Pause video and timer
            pauseTimer()
            pauseVideo()

            // Get the current video timestamp (end of round)
            let endTimestamp = videoPlayerView.player?.currentTime().seconds ?? 0

            // Only call this function when ending a round
            requestRoundEndReason { [weak self] isEndedByTime in
                guard let self = self else { return }

                // Request hit counts from the user
                self.requestHitsCount { blueHits, redHits in
                    // Update the current round with final information
                    currentRound.duration = self.chronoDuration - self.remainingTime
                    currentRound.blueHits = blueHits
                    currentRound.redHits = redHits

                    // Determine the winner and decision
                    let (winner, decision) = currentRound.determineWinner(isEndedByTime: isEndedByTime)

                    // Update the round with the result
                    currentRound.roundWinner = winner?.rawValue == "blue" ? fight.blueFighterId : fight.redFighterId
                    currentRound.victoryDecision = decision

                    // Show the round summary
                    self.showRoundSummary(round: currentRound, winner: winner) {
                        // Save the round data to Firebase
                        self.saveRoundToFirebase(currentRound, endTimestamp: endTimestamp)
                    }
                }
            }
        }

        // Prepare for the next round without asking for round end reason
        func prepareNextRound(previousEndTimestamp: TimeInterval) {
            guard let fight = fight else { return }

            let nextRoundNumber = (currentRound?.roundNumber ?? 0) + 1

            // Request the pause duration before starting the next round
            requestPauseDuration { [weak self] pauseDuration in
                guard let self = self else { return }
                currentRoundStartTime = previousEndTimestamp + pauseDuration

                // Set the new start time based on the end timestamp + pause duration

                // Create a new round object with the new start time
                let newRound = Round(
                    fightId: fight.id ?? "",
                    roundNumber: nextRoundNumber,
                    chronoDuration: self.videoPlayerView.player?.currentItem?.duration.seconds ?? 0,
                    duration: 0,
                    roundTime: currentRound?.roundTime ?? 120,
                    blueFighterId: fight.blueFighterId,
                    redFighterId: fight.redFighterId,
                    actions: [],
                    videoReplays: [],
                    isSynced: false
                )

                // Set the current round and update the start time
                self.currentRound = newRound
                self.currentRound?.startTime = currentRoundStartTime

                // Reset scores and UI
                self.resetScores()
                self.manageScores()

                // Seek the video to the new start time and prepare to start the new round
                self.seekVideo(to: CMTime(seconds: currentRoundStartTime, preferredTimescale: 600))

                // Display an alert to start the new round
                let alertController = UIAlertController(title: "New Round", message: "Round \(nextRoundNumber) is ready to start.", preferredStyle: .alert)
                let startAction = UIAlertAction(title: "Start", style: .default) { _ in
                    self.startTimer()
                    self.playVideo()
                }
                alertController.addAction(startAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }

        func requestPauseDuration(completion: @escaping (Double) -> Void) {
            let alertController = UIAlertController(title: "Pause Duration", message: "Enter the pause duration (in seconds):", preferredStyle: .alert)

            alertController.addTextField { textField in
                textField.placeholder = "Pause Duration"
                textField.keyboardType = .numberPad
            }

            let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
                let pauseDuration = Double(alertController.textFields?.first?.text ?? "0") ?? 0
                completion(pauseDuration)
            }

            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
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


