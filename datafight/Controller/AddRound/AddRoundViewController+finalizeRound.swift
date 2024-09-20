//
//  AddRoundViewController+finalizeRound.swift
//  datafight
//
//  Created by younes ouasmi on 28/08/2024.
//


import UIKit
import FirebaseFirestore
import CoreMedia

extension AddRoundViewController {
    

    
    func setCurrentRoundNumber() {
        guard let fight = fight else {
            currentRoundNumber = 1
            print("Fight not found, setting currentRoundNumber to 1")
            return
        }
        
        currentRoundNumber = (fight.roundIds?.count ?? 0) + 1
        print("Current round number set  p to: \(currentRoundNumber)")
    }
    
    // MARK: - Round End Process
    
    func endRound() {
        guard let currentRound = currentRound, let fight = fight else {
            print("Error: No active round or fight")
            showAlert(title: "Error", message: "No active round or fight")
            return
        }
        
        let currentRoundNumber = (fight.roundIds?.count ?? 0) + 1
        print("Current round number: \(currentRoundNumber)")
        
        if currentRoundNumber > MAX_ROUNDS {
            print("Error: Maximum number of rounds reached")
            showAlert(title: "Error", message: "Maximum number of rounds (3) has been reached.")
            return
        }
        
        pauseTimer()
        
        let endTimestamp = videoPlayerView.player?.currentTime().seconds ?? 0
        print("End timestamp: \(endTimestamp)")
        
        requestRoundEndReason { [weak self] isEndedByTime in
            guard let self = self else { return }
            print("Round ended by time: \(isEndedByTime)")
            
            self.requestHitsCount { blueHits, redHits in
                print("Hits count - Blue: \(blueHits), Red: \(redHits)")
                var updatedRound = currentRound
                updatedRound.duration = self.chronoDuration - self.remainingTime
                updatedRound.blueHits = blueHits
                updatedRound.redHits = redHits
                
                let (winner, decision) = updatedRound.determineWinner(isEndedByTime: isEndedByTime, determiner: self)
                print("Initial decision: \(String(describing: winner))")
                
                self.finalizeRoundDecision(currentRound: updatedRound, fight: fight, winner: winner, decision: decision) { finalizedRound in
                    self.currentRound = finalizedRound // Mettre à jour self.currentRound avec la version finalisée
                    self.showRoundSummary(round: finalizedRound, winner: FighterColor(rawValue: finalizedRound.roundWinner == fight.blueFighterId ? "blue" : "red")) {
                        self.saveRoundToFirebase(finalizedRound, endTimestamp: endTimestamp) {
                            self.checkFightWinner(endTimestamp: endTimestamp)
                        }
                    }
                }
            }
        }
    }

    func finalizeRoundDecision(currentRound: Round, fight: Fight, winner: FighterColor?, decision: VictoryDecision, completion: @escaping (Round) -> Void) {
        var localRound = currentRound // Créer une copie locale

        if decision == .referee {
            print("Referee decision required")
            self.handleRefereeDecision { refereeDecision in
                print("Referee decision received: \(refereeDecision)")
                localRound.roundWinner = refereeDecision == .blue ? fight.blueFighterId : fight.redFighterId
                localRound.victoryDecision = .referee
                completion(localRound)
            }
        }
 else {
            print("Winner determined: \(winner?.rawValue ?? "None"), Decision: \(decision)")
            localRound.roundWinner = winner?.rawValue == "blue" ? fight.blueFighterId : fight.redFighterId
            localRound.victoryDecision = decision
            completion(localRound)
        }
    }
    func handleRefereeDecision(completion: @escaping (FighterColor) -> Void) {
        DispatchQueue.main.async {
            print("Presenting Referee Decision Alert") // Add this line

            let alert = UIAlertController(title: "Referee Decision", message: "Please select the winner as determined by the referees", preferredStyle: .alert)

            let blueAction = UIAlertAction(title: "Blue Fighter", style: .default) { _ in
                print("Blue Fighter selected")
                completion(.blue)
            }
            
            let redAction = UIAlertAction(title: "Red Fighter", style: .default) { _ in
                print("Red Fighter selected")
                completion(.red)
            }

            alert.addAction(blueAction)
            alert.addAction(redAction)

            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }

            if self.isViewLoaded && self.view.window != nil {
                print("Showing alert")
                self.present(alert, animated: true, completion: nil)
            } else {
                print("Warning: Tried to present alert but the view was not in hierarchy")
            }
        }
    }
    func checkFightWinner(endTimestamp: TimeInterval) {
        print("🔄 Checking fight winner at end timestamp: \(endTimestamp)")
        
        guard let fight = fight else {
            print("❌ Error: No fight found")
            return
        }
        
        calculateRoundWins(for: fight) { [weak self] blueRoundsWon, redRoundsWon in
            guard let self = self else {
                print("❌ Error: self is nil")
                return
            }
            
            print("✅ Rounds won - Blue: \(blueRoundsWon), Red: \(redRoundsWon)")
           
            // Mettre à jour les labels de round gagnés
                    DispatchQueue.main.async {
                        self.bluewinningroundlabel.text = "\(blueRoundsWon)"
                        self.redwinningroundlabel.text = "\(redRoundsWon)"
                    }
            
            let totalRounds = fight.roundIds?.count ?? 0
            print("🔢 Total rounds: \(totalRounds)")
            
            let isMajorityReached = blueRoundsWon == 2 || redRoundsWon == 2
            
            print("📊 Majority reached: \(isMajorityReached)")
            
            if isMajorityReached {
                let winner = blueRoundsWon > redRoundsWon ? fight.blueFighterId : fight.redFighterId
                let method = "Majority"
                print("🏅 Fight winner determined: \(winner), Method: \(method)")
                
                let fightResult = FightResult(
                    winner: winner,
                    method: method,
                    totalScore: (blue: blueRoundsWon, red: redRoundsWon)
                )
                print("📊 Fight result: \(fightResult)")
                
                self.updateFightWithResult(fightResult)
            } else if totalRounds < MAX_ROUNDS {
                print("⚠️ Preparing next round")
                self.prepareNextRound(previousEndTimestamp: endTimestamp)
            } else {
                print("❗ All rounds completed, finalizing fight")
                // Déterminer le gagnant basé sur le nombre de rounds gagnés
                let winner = blueRoundsWon > redRoundsWon ? fight.blueFighterId : fight.redFighterId
                let method = "Decision"
                
                let fightResult = FightResult(
                    winner: winner,
                    method: method,
                    totalScore: (blue: blueRoundsWon, red: redRoundsWon)
                )
                print("📊 Final fight result: \(fightResult)")
                
                self.updateFightWithResult(fightResult)
            }
        }
    }
    
    
    // Finalizes the round with a decision
    private func finalizeRound(_ round: Round, with decision: VictoryDecision, endTimestamp: TimeInterval) {
        print("Finalizing round with decision: \(decision)")
        var updatedRound = round
        updatedRound.duration = endTimestamp - (updatedRound.startTime ?? 0)
        updatedRound.victoryDecision = decision
        updatedRound.determineRoundWinner()
        
        saveRoundToFirebase(updatedRound, endTimestamp: endTimestamp) { [weak self] in
            print("Round saved to Firebase")
            self?.resetForNextRound()
            self?.checkFightWinner(endTimestamp: endTimestamp)
        }
    }
    
    // MARK: - Round Management
    
    private func resetForNextRound() {
        print("Resetting for next round")
        currentRound = nil
        resetTimer()
        resetScores()
    }
    
    func prepareNextRound(previousEndTimestamp: TimeInterval) {
        print("Preparing next round")
        print("Previous round end time: \(previousEndTimestamp)")
        
        guard let fight = fight else {
            print("Error: No fight found")
            return
        }
        
        let nextRoundNumber = (currentRound?.roundNumber ?? 0) + 1
        print("Next round number: \(nextRoundNumber)")
        
        if nextRoundNumber > MAX_ROUNDS {
            print("Error: Maximum number of rounds reached")
            showAlert(title: "Fight Ended", message: "All rounds completed. Please finalize the fight.")
            return
        }
        
        requestPauseDuration { [weak self] pauseDuration in
            guard let self = self else { return }
            print("Pause duration: \(pauseDuration)")
            let newStartTime = previousEndTimestamp + pauseDuration
            
            let newRound = Round(
                fightId: fight.id ?? "",
                roundNumber: nextRoundNumber,
                chronoDuration: self.videoPlayerView.player?.currentItem?.duration.seconds ?? 0,
                duration: 0,
                roundTime: self.currentRound?.roundTime ?? 120,
                blueFighterId: fight.blueFighterId,
                redFighterId: fight.redFighterId,
                actions: [],
                videoReplays: [],
                isSynced: false,
                startTime: newStartTime
            )

            self.currentRound = newRound
            print("New round created: \(newRound)")
            
            self.resetScores()
            self.manageScores()
            
            self.updateVideoTimestamps(startTimestamp: newStartTime, endTimestamp: nil, roundNumber: nextRoundNumber)
            
            self.seekVideo(to: CMTime(seconds: newStartTime, preferredTimescale: 600))
            
            // Mettez à jour les labels pour le nombre de rounds gagnés
                   DispatchQueue.main.async {
                       self.bluewinningroundlabel.text = "\(self.blueRoundWon)"
                       self.redwinningroundlabel.text = "\(self.redRoundWon)"
                   }
            
            // Notify the user that the next round is ready
            let alertController = UIAlertController(title: "New Round", message: "Round \(nextRoundNumber) is ready to start.", preferredStyle: .alert)
            let startAction = UIAlertAction(title: "Start", style: .default) { _ in
                print("Starting next round")
                self.startTimer()
                self.playVideo()
            }
            alertController.addAction(startAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    func requestPauseDuration(completion: @escaping (Double) -> Void) {
        print("Requesting pause duration")
        let alertController = UIAlertController(title: "Pause Duration", message: "Enter the pause duration (in seconds):", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Pause Duration"
            textField.keyboardType = .numberPad
        }
        let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
            let pauseDuration = Double(alertController.textFields?.first?.text ?? "0") ?? 0
            print("Pause duration entered: \(pauseDuration)")
            completion(pauseDuration)
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func requestRoundEndReason(completion: @escaping (Bool) -> Void) {
        print("Requesting round end reason")
        let alertController = UIAlertController(title: "End of Round", message: "Did the round end by time expiration?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            print("Round ended by time expiration")
            completion(true)
        }
        let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
            print("Round did not end by time expiration")
            completion(false)
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func requestHitsCount(completion: @escaping (Int, Int) -> Void) {
        print("Requesting hits count")
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
                print("Error: Invalid hits count entered")
                completion(0, 0)
                return
            }
            print("Hits count entered - Blue: \(blueHits), Red: \(redHits)")
            completion(blueHits, redHits)
        }
        
        alertController.addAction(submitAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Firebase and Video
    
    func saveRoundToFirebase(_ round: Round, endTimestamp: TimeInterval, completion: @escaping () -> Void) {
        print("Saving round to Firebase")
        guard let fight = fight else {
            print("Error: No fight found")
            return
        }
        
        var updatedRound = round
        updatedRound.endTime = endTimestamp
        updatedRound.chronoDuration = chronoDuration
        
        FirebaseService.shared.saveRoundAndUpdateFight(updatedRound, for: fight) { [weak self] result in
            switch result {
            case .success(let roundId):
                print("Round saved successfully with ID: \(roundId)")
                // Mise à jour des timestamps vidéo
                self?.updateVideoTimestamps(startTimestamp: updatedRound.startTime ?? 0,
                                            endTimestamp: endTimestamp,
                                            roundNumber: updatedRound.roundNumber)
                completion()
            case .failure(let error):
                print("Failed to save round: \(error.localizedDescription)")
                self?.showAlert(title: "Error", message: "Failed to save round: \(error.localizedDescription)")
                completion()
            }
        }
    }
    
    func updateVideoTimestamps(startTimestamp: TimeInterval, endTimestamp: TimeInterval?, roundNumber: Int) {
        print("Updating video timestamps: start - \(startTimestamp), end - \(String(describing: endTimestamp)), round - \(roundNumber)")

        print("Updating video timestamps")
        guard let fight = fight, let videoId = fight.videoId else {
            print("Error: Missing fight or videoId")
            return
        }
        
        FirebaseService.shared.getVideo(by: videoId) { [weak self] result in
            switch result {
            case .success(var video):
                print("Successfully retrieved video")
                
                video.updateOrAddRoundTimestamp(
                    roundNumber: roundNumber,
                    start: startTimestamp,
                    end: endTimestamp
                )
                
                // Update video in Firebase
                FirebaseService.shared.updateVideo(video) { updateResult in
                    switch updateResult {
                    case .success:
                        print("Video timestamps updated successfully")
                    case .failure(let error):
                        print("Failed to update video timestamps: \(error.localizedDescription)")
                        self?.showAlert(title: "Error", message: "Failed to update video timestamps: \(error.localizedDescription)")
                    }
                }
                
            case .failure(let error):
                print("Failed to retrieve video: \(error.localizedDescription)")
                self?.showAlert(title: "Error", message: "Failed to retrieve video: \(error.localizedDescription)")
            }
        }
    }
    // Show the fight completion
    func showFightCompletionAlert(result: FightResult) {
        print("Showing fight completion alert")
        let message = "Fight completed. Winner: \(result.winner), Method: \(result.method)"
        let alertController = UIAlertController(title: "Fight Completed", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            print("Returning to previous view controller")
            self?.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showFightCompletion(result: FightResult) {
        print("Showing fight completion result")
        
        guard let fightResultVC = storyboard?.instantiateViewController(withIdentifier: "FightResultViewController") as? FightResultViewController,
              let fight = self.fight else {
            print("Error: Unable to instantiate FightResultViewController or no fight available")
            return
        }
        
        // Récupérer les fighters
        FirebaseService.shared.getFighter(id: fight.blueFighterId) { [weak self] blueResult in
            FirebaseService.shared.getFighter(id: fight.redFighterId) { [weak self] redResult in
                guard let self = self else { return }
                
                switch (blueResult, redResult) {
                case (.success(let blueFighter), .success(let redFighter)):
                    // Configurer le FightResultViewController
                    fightResultVC.fight = fight
                    fightResultVC.rounds = self.rounds
                    fightResultVC.fightResult = result
                    fightResultVC.blueFighter = blueFighter
                    fightResultVC.redFighter = redFighter
                    
                    fightResultVC.onDismiss = { [weak self] in
                        print("Returning to previous view controller")
                        self?.navigationController?.popViewController(animated: true)
                    }
                    
                    // Présenter le FightResultViewController
                    DispatchQueue.main.async {
                        fightResultVC.modalPresentationStyle = .fullScreen // ou .formSheet pour iPad
                        self.present(fightResultVC, animated: true, completion: nil)
                    }
                    
                case (.failure(let blueError), _):
                    print("Error retrieving blue fighter: \(blueError)")
                    self.showAlert(title: "Error", message: "Failed to retrieve blue fighter")
                    
                case (_, .failure(let redError)):
                    print("Error retrieving red fighter: \(redError)")
                    self.showAlert(title: "Error", message: "Failed to retrieve red fighter")
                }
            }
        }
    }
    
    func showRoundSummary(round: Round, winner: FighterColor?, completion: @escaping () -> Void) {
        print("Showing round summary")
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
            print("Round summary acknowledged")
            completion()
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
