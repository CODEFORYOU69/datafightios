//
    //  AddRoundViewController+fcalculate+round+fight.swift
//  datafight
//
//  Created by younes ouasmi on 03/09/2024.
//

import UIKit

extension AddRoundViewController {
    func calculateScore(for color: FighterColor) -> Int {
        let directPoints = currentRound?.actions.filter { $0.color == color && $0.actionType != .gamJeon && $0.isActive }.reduce(0) { $0 + $1.points } ?? 0
        let opponentColor: FighterColor = color == .blue ? .red : .blue
        let gamjeonPoints = currentRound?.actions.filter { $0.color == opponentColor && $0.actionType == .gamJeon && $0.isActive }.count ?? 0
        return directPoints + gamjeonPoints
    }
    
    func countGamjeons(for color: FighterColor) -> Int {
        return currentRound?.actions.filter { $0.color == color && $0.actionType == .gamJeon && $0.isActive }.count ?? 0
    }
    
    func saveRoundData(_ round: Round) {
        guard let fight = fight else { return }
        
        FirebaseService.shared.saveRound(round, for: fight) { [weak self] result in
            switch result {
            case .success:
                self?.updateFightResult(with: round)
                self?.showAlert(title: "Success", message: "Round saved successfully")
            case .failure(let error):
                self?.showAlert(title: "Error", message: "Failed to save round: \(error.localizedDescription)")
            }
        }
    }
    func updateFightResult(with round: Round) {
        guard var fight = fight else { return }
        
        if fight.roundIds == nil {
            fight.roundIds = []
        }
        fight.roundIds?.append(round.id ?? "")
        
        calculateRoundWins(for: fight) { [weak self] blueRoundsWon, redRoundsWon in
            guard let self = self else { return }
            
            if blueRoundsWon == 2 || redRoundsWon == 2 || self.isDirectVictory(round.victoryDecision) {
                let winner = blueRoundsWon > redRoundsWon ? fight.blueFighterId : fight.redFighterId
                let method = round.victoryDecision?.rawValue ?? "Points"
                
                self.calculateTotalScore(for: .blue) { blueTotalScore in
                    self.calculateTotalScore(for: .red) { redTotalScore in
                        fight.fightResult = FightResult(
                            winner: winner,
                            method: method,
                            totalScore: (blue: blueTotalScore, red: redTotalScore)
                        )
                        
                        FirebaseService.shared.updateFight(fight) { result in
                            switch result {
                            case .success:
                                self.showAlert(title: "Success", message: "Fight updated successfully")
                            case .failure(let error):
                                self.showAlert(title: "Error", message: "Failed to update fight: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func isDirectVictory(_ decision: VictoryDecision?) -> Bool {
           guard let decision = decision else { return false }
           return [.knockout, .technicalKnockout, .disqualification].contains(decision)
       }
    func calculateTotalScore(for color: FighterColor, completion: @escaping (Int) -> Void) {
        guard let fight = fight else {
            completion(0)
            return
        }
        
        var totalScore = 0
        let group = DispatchGroup()
        
        fight.roundIds?.forEach { roundId in
            group.enter()
            FirebaseService.shared.getRound(id: roundId, for: fight) { result in
                switch result {
                case .success(let round):
                    totalScore += (color == .blue ? round.blueScore : round.redScore)
                case .failure(let error):
                    print("Failed to get round with ID \(roundId): \(error.localizedDescription)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(totalScore)
        }
    }
    
    
    func calculateRoundWins(for fight: Fight, completion: @escaping (Int, Int) -> Void) {
        var blueRoundsWon = 0
        var redRoundsWon = 0
        
        let dispatchGroup = DispatchGroup()
        
        fight.roundIds?.forEach { roundId in
            dispatchGroup.enter()
            
            FirebaseService.shared.getRound(id: roundId, for: fight) { result in
                switch result {
                case .success(let savedRound):
                    if savedRound.roundWinner == fight.blueFighterId {
                        blueRoundsWon += 1
                    } else if savedRound.roundWinner == fight.redFighterId {
                        redRoundsWon += 1
                    }
                case .failure(let error):
                    print("Failed to get round: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(blueRoundsWon, redRoundsWon)
        }
    }
}
