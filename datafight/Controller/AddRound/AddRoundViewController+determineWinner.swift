//
//  AddRoundViewController+determineWinner.swift
//  datafight
//
//  Created by younes ouasmi on 05/09/2024.
//
import UIKit

// MARK: - Victory Decision Alert Extension
extension AddRoundViewController {
    
    // MARK: - Show Victory Decision Alert
    // Displays an action sheet for the user to select a victory decision.
    func showVictoryDecisionAlert(completion: @escaping (VictoryDecision) -> Void) {
        print("Showing Victory Decision Alert")
        let alertController = UIAlertController(title: "Select Victory Decision", message: nil, preferredStyle: .actionSheet)
        
        for decision in VictoryDecision.allCases {
            let action = UIAlertAction(title: "\(decision.rawValue)", style: .default) { _ in
                print("Selected Victory Decision: \(decision.rawValue)")
                completion(decision)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Victory Decision selection cancelled, defaulting to referee")
            completion(.referee)  // Default to referee decision if cancelled
        }
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Show Winner Selection Alert
    // Presents an alert for the user to select the winning fighter.
    func showWinnerSelectionAlert(completion: @escaping (FighterColor) -> Void) {
        print("Showing Winner Selection Alert")
        let alertController = UIAlertController(title: "Select Winner", message: nil, preferredStyle: .alert)
        
        let blueAction = UIAlertAction(title: "Blue Fighter", style: .default) { _ in
            print("Blue Fighter selected as winner")
            completion(.blue)
        }
        alertController.addAction(blueAction)
        
        let redAction = UIAlertAction(title: "Red Fighter", style: .default) { _ in
            print("Red Fighter selected as winner")
            completion(.red)
        }
        alertController.addAction(redAction)
        
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Determine Non-Time End Winner
    // Determines the winner of a round based on gamjeon penalties or user input if no automatic winner is found.
    func determineNonTimeEndWinner() -> (winner: FighterColor?, decision: VictoryDecision) {
        print("Determining non-time end winner")
        if let currentRound = currentRound {
            if currentRound.blueGamJeon >= 5 {
                print("Blue has 5 or more Gamjeons, Red wins by Punitive Declaration")
                return (.red, .punitiveDeclaration)
            } else if currentRound.redGamJeon >= 5 {
                print("Red has 5 or more Gamjeons, Blue wins by Punitive Declaration")
                return (.blue, .punitiveDeclaration)
            }
        }
        
        print("No automatic winner, requesting user input")
        return requestVictoryDecisionAndWinner()
    }

    // MARK: - Request Victory Decision and Winner
    // Requests the user to select a victory decision and winner if no automatic outcome is determined.
    func requestVictoryDecisionAndWinner() -> (winner: FighterColor?, decision: VictoryDecision) {
        print("Requesting Victory Decision and Winner from user")
        var selectedDecision: VictoryDecision?
        var selectedWinner: FighterColor?
        
        let group = DispatchGroup()
        
        group.enter()
        DispatchQueue.main.async {
            self.showVictoryDecisionAlert { decision in
                selectedDecision = decision
                print("Victory Decision selected: \(decision.rawValue)")
                group.leave()
            }
        }
        
        group.enter()
        DispatchQueue.main.async {
            self.showWinnerSelectionAlert { winner in
                selectedWinner = winner
                print("Winner selected: \(winner)")
                group.leave()
            }
        }
        
        group.wait()
        
        print("Final decision: Winner - \(selectedWinner?.rawValue ?? "None"), Decision - \(selectedDecision?.rawValue ?? "referee")")
        return (selectedWinner, selectedDecision ?? .referee)
    }

    // MARK: - Present Referee Decision Alert
    // Displays an alert to request the referee's decision if no winner is automatically determined.
    func presentRefereeDecisionAlert(completion: @escaping (FighterColor) -> Void) {
        print("Entering presentRefereeDecisionAlert")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("Self is nil in presentRefereeDecisionAlert")
                return
            }
            
            print("Creating UIAlertController for referee decision")
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
                print("Configuring popoverPresentationController for iPad")
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            print("Checking if view is loaded and in window")
            if self.isViewLoaded && self.view.window != nil {
                print("View is loaded and in window")
                if let presentedVC = self.presentedViewController {
                    print("Another view controller is already presented: \(type(of: presentedVC))")
                    presentedVC.dismiss(animated: true) {
                        self.present(alert, animated: true) {
                            print("Referee decision alert presented successfully")
                        }
                    }
                } else {
                    print("No view controller currently presented, showing alert")
                    self.present(alert, animated: true) {
                        print("Referee decision alert presented successfully")
                    }
                }
            } else {
                print("View is not loaded or not in window, cannot present alert")
                // Optionally, you could try to present the alert on the root view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    print("Attempting to present alert on root view controller")
                    rootVC.present(alert, animated: true) {
                        print("Referee decision alert presented successfully on root view controller")
                    }
                } else {
                    print("Could not find root view controller to present alert")
                }
            }
        }
    }
}
