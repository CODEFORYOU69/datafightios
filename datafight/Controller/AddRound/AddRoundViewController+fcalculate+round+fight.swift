//AddRoundViewController+fcalculate+round+fight.swift
//  datafight
//
//  Created by younes ouasmi on 03/09/2024.
//

import UIKit

extension AddRoundViewController {
    func calculateScore(for color: FighterColor) -> Int {
        print("Calculating score for \(color)")
        let directPoints = currentRound?.actions.filter { $0.color == color && $0.actionType != .gamJeon && ($0.isActive != nil) }.reduce(0) { $0 + $1.points } ?? 0
        let opponentColor: FighterColor = color == .blue ? .red : .blue
        let gamjeonPoints = currentRound?.actions.filter { $0.color == opponentColor && $0.actionType == .gamJeon && ($0.isActive != nil) }.count ?? 0
        let totalPoints = directPoints + gamjeonPoints
        print("Total points for \(color): \(totalPoints) (Direct: \(directPoints), Gamjeon: \(gamjeonPoints))")
        return totalPoints
    }
    
    func countGamjeons(for color: FighterColor) -> Int {
        let count = currentRound?.actions.filter { $0.color == color && $0.actionType == .gamJeon && ($0.isActive != nil) }.count ?? 0
        print("Gamjeons for \(color): \(count)")
        return count
    }
    
    func saveRoundData(_ round: Round) {
        print("Saving round data")
        guard let fight = fight else {
            print("Error: No fight found")
            return
        }
        
        FirebaseService.shared.saveRound(round, for: fight) { [weak self] result in
            switch result {
            case .success:
                print("Round saved successfully")
                self?.updateFightResult(with: round)
                self?.showAlert(title: "Success", message: "Round saved successfully")
            case .failure(let error):
                print("Failed to save round: \(error.localizedDescription)")
                self?.showAlert(title: "Error", message: "Failed to save round: \(error.localizedDescription)")
            }
        }
    }
    
    func updateFightWithResult(_ result: FightResult) {
        print("Updating fight with result: \(result)")
        guard var updatedFight = fight else {
            print("Error: No fight found")
            return
        }
        
        updatedFight.fightResult = result
        print("Updated fight: \(updatedFight)")
        
        FirebaseService.shared.updateFight(updatedFight) { [weak self] updateResult in
            switch updateResult {
            case .success:
                print("Fight updated successfully")
                self?.showFightCompletion(result: result)
            case .failure(let error):
                print("Failed to update fight: \(error.localizedDescription)")
                print("Error details: \(error)")
                self?.showAlert(title: "Error", message: "Failed to update fight: \(error.localizedDescription)")
            }
        }
    }
    func updateRounds(completion: @escaping () -> Void) {
        guard let fight = self.fight else {
            print("Error: No fight available")
            completion()
            return
        }
        
        FirebaseService.shared.getAllRoundsForFight(fight) { [weak self] result in
            switch result {
            case .success(let fetchedRounds):
                self?.rounds = fetchedRounds
                print("Successfully updated rounds. Total rounds: \(fetchedRounds.count)")
            case .failure(let error):
                print("Failed to fetch rounds: \(error.localizedDescription)")
            }
            completion()
        }
    }
    func updateFightResult(with round: Round) {
        print("Updating fight result")
        guard var fight = fight else {
            print("Error: No fight found")
            return
        }
        
        if fight.roundIds == nil {
            fight.roundIds = []
        }
        fight.roundIds?.append(round.id ?? "")
        
        calculateRoundWins(for: fight) { [weak self] blueRoundsWon, redRoundsWon in
            guard let self = self else { return }
            
            print("Rounds won - Blue: \(blueRoundsWon), Red: \(redRoundsWon)")
            
            if blueRoundsWon == 2 || redRoundsWon == 2 || self.isDirectVictory(round.victoryDecision) {
                let winner = blueRoundsWon > redRoundsWon ? fight.blueFighterId : fight.redFighterId
                let method = round.victoryDecision?.rawValue ?? "Points"
                
                print("Fight winner determined: \(winner), Method: \(method)")
                
                self.calculateTotalScore(for: .blue) { blueTotalScore in
                    self.calculateTotalScore(for: .red) { redTotalScore in
                        let fightResult = FightResult(
                            winner: winner,
                            method: method,
                            totalScore: (blue: blueTotalScore, red: redTotalScore)
                        )
                        
                        print("Final fight result: \(fightResult)")
                        
                        FirebaseService.shared.updateFight(fight) { result in
                            switch result {
                            case .success:
                                print("Fight updated successfully")
                                self.showAlert(title: "Success", message: "Fight updated successfully")
                            case .failure(let error):
                                print("Failed to update fight: \(error.localizedDescription)")
                                self.showAlert(title: "Error", message: "Failed to update fight: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func isDirectVictory(_ decision: VictoryDecision?) -> Bool {
        print("Checking if it's a direct victory")
        guard let decision = decision else {
            print("No decision provided, not a direct victory")
            return false
        }
        let result = [.knockout, .technicalKnockout, .disqualification].contains(decision)
        print("Is direct victory: \(result), Decision: \(decision)")
        return result
    }
    func calculateTotalScore(for color: FighterColor, completion: @escaping (Int) -> Void) {
        print("Calculating total score for \(color)")
        guard let fight = fight else {
            print("Error: No fight found")
            completion(0)
            return
        }
        
        FirebaseService.shared.getAllRoundsForFight(fight) { result in
            switch result {
            case .success(let rounds):
                let totalScore = rounds.reduce(0) { $0 + (color == .blue ? $1.blueScore : $1.redScore) }
                print("Total score for \(color): \(totalScore)")
                completion(totalScore)
            case .failure(let error):
                print("Failed to get rounds: \(error.localizedDescription)")
                completion(0)
            }
        }
    }
    
    func calculateRoundWins(for fight: Fight, completion: @escaping (Int, Int) -> Void) {
        print("🔄 Starting calculation of round wins for fight: \(fight.id ?? "Unknown fight ID")")
           print("Blue Fighter ID: \(fight.blueFighterId)")
           print("Red Fighter ID: \(fight.redFighterId)")
           print("Round IDs: \(fight.roundIds ?? [])")
        
        FirebaseService.shared.getAllRoundsForFight(fight) { result in
            switch result {
            case .success(let rounds):
                print("✅ Successfully fetched rounds. Total rounds: \(rounds.count)")
                
                let blueRoundsWon = rounds.filter { $0.roundWinner == fight.blueFighterId }.count
                let redRoundsWon = rounds.filter { $0.roundWinner == fight.redFighterId }.count
                
                rounds.forEach { round in
                    if round.roundWinner == fight.blueFighterId {
                        print("🔵 Blue won round \(round.roundNumber)")
                    } else if round.roundWinner == fight.redFighterId {
                        print("🔴 Red won round \(round.roundNumber)")
                    } else {
                        print("❔ No winner for round \(round.roundNumber)")
                    }
                }
                
                print("🏆 Final round wins - Blue: \(blueRoundsWon), Red: \(redRoundsWon)")
                completion(blueRoundsWon, redRoundsWon)
            case .failure(let error):
                print("❌ Failed to get rounds: \(error.localizedDescription)")
                completion(0, 0)
            }
        }
    }

}
