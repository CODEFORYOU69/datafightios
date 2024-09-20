//
//  AddRoundViewController+UISetup.swift AddRoundViewController+UISetup.swift AddRoundViewController+UISetupViewController.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import UIKit
import AVFoundation
import FlagKit

extension AddRoundViewController {
    

    func setupUI() {
        guard let fight = fight,
              let blueFighter = blueFighter,
              let redFighter = redFighter,
              let event = event else {
            print("Missing fight data")
            return
            

        }

        matchNumber.text = "\(fight.fightNumber)"
        infoFightLabel.text = "\(event.eventName) | \(event.eventType) | \(fight.weightCategory)"

        bluefighterlabel.text = "\(blueFighter.firstName) \(blueFighter.lastName)"
        redfighterlabel.text = "\(redFighter.firstName) \(redFighter.lastName)"

        bluecountrylabel.text = blueFighter.country
        redcountrylabel.text = redFighter.country

        // Set flags
        if let blueFlag = Flag(countryCode: blueFighter.country) {
            blueflagimage.image = blueFlag.image(style: .roundedRect)
        }
        if let redFlag = Flag(countryCode: redFighter.country) {
            redflagimage.image = redFlag.image(style: .roundedRect)
        }

        // Initialize scores and other labels
        bluescore.text = "0"
        redscore.text = "0"
        bluegamjeonlabel.text = "0"
        redgamjeonlabel.text = "0"
        bluewinningroundlabel.text = "0"
        redwinningroundlabel.text = "0"
        bluehitslabel.text = "0"
        redhitslabel.text = "0"

        // Setup icons views (you'll need to implement this based on your design)
        
        pauseResumeButton.setTitle("Pause", for: .normal)

        // Set the font size
        pauseResumeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 40)

        // Rotate the label to make the text vertical
        pauseResumeButton.titleLabel?.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)

        // Adjust the button title label position
        pauseResumeButton.titleLabel?.numberOfLines = 1
        pauseResumeButton.titleLabel?.lineBreakMode = .byClipping

        // Optional: Adjust the content alignment
        pauseResumeButton.contentVerticalAlignment = .center
        pauseResumeButton.contentHorizontalAlignment = .center

    }

    func setupProgressView() {
        // Initialiser la progressView
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0.0
        progressView.isHidden = true // Caché par défaut

        // Ajouter la progressView à la vue principale (`view`)
        view.addSubview(progressView)

        // Configurer les contraintes pour positionner la progressView sous `videoPlayerContainerView`
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0), // Aligner avec le bord gauche de la vue parent
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0), // Aligner avec le bord droit de la vue parent
            progressView.topAnchor.constraint(equalTo: blueiconescored.topAnchor, constant: 15), // Placer en dessous de la vidéo avec un petit espace
            progressView.heightAnchor.constraint(equalToConstant: 4) // Définir une hauteur fixe pour la barre de progression
        ])
    }



    func manageScores() {
           calculateScores()
           updateScoreLabels()
           updateGamjeonLabels()
           updateHitsLabels()
       }
    
    private func calculateScores() {
           guard let currentRound = currentRound else { return }
           
           blueScore = calculateScore(for: .blue, in: currentRound)
           redScore = calculateScore(for: .red, in: currentRound)
       }

       private func calculateScore(for color: FighterColor, in round: Round) -> Int {
           let directPoints = round.actions.filter { $0.color == color && $0.actionType != .gamJeon && ($0.isActive != nil) }.reduce(0) { $0 + $1.points }
           let opponentColor: FighterColor = color == .blue ? .red : .blue
           let gamjeonPoints = round.actions.filter { $0.color == opponentColor && $0.actionType == .gamJeon && ($0.isActive != nil) }.count
           return directPoints + gamjeonPoints
       }

       private func updateScoreLabels() {
           DispatchQueue.main.async { [weak self] in
               guard let self = self else { return }
               self.bluescore.text = "\(self.blueScore)"
               self.redscore.text = "\(self.redScore)"
           }
       }

       private func updateGamjeonLabels() {
           DispatchQueue.main.async { [weak self] in
               guard let self = self, let currentRound = self.currentRound else { return }
               self.bluegamjeonlabel.text = "\(self.countGamjeons(for: .blue, in: currentRound))"
               self.redgamjeonlabel.text = "\(self.countGamjeons(for: .red, in: currentRound))"
           }
       }

       private func countGamjeons(for color: FighterColor, in round: Round) -> Int {
           round.actions.filter { $0.color == color && $0.actionType == .gamJeon && ($0.isActive != nil) }.count
       }
    private func updateHitsLabels() {
           DispatchQueue.main.async { [weak self] in
               guard let self = self, let currentRound = self.currentRound else { return }
               self.bluehitslabel.text = "\(currentRound.blueHits)"
               self.redhitslabel.text = "\(currentRound.redHits)"
           }
       }
    func printCurrentRoundActions() {
        guard let currentRound = currentRound else {
            print("No current round available")
            return
        }
        
        print("\n--- Current Round Actions ---")
        print("Round Number: \(currentRound.roundNumber)")
        print("Total Actions: \(currentRound.actions.count)")
        print("Active Actions: \(currentRound.actions.filter { $0.isActive ?? true}.count)")
        
        for (index, action) in currentRound.actions.enumerated() {
            print("\nAction \(index + 1):")
            print("  Type: \(action.actionType)")
            print("  Color: \(action.color)")
            print("  Is Active: \(String(describing: action.isActive))")
            print("  Timestamp: \(action.timeStamp)")
            if let technique = action.technique {
                print("  Technique: \(technique)")
            }
            print("  Points: \(action.points)")  // Cette ligne a été modifiée
            if let gamjeonType = action.gamjeonType {
                print("  Gamjeon Type: \(gamjeonType)")
            }
        }
        
        print("\nCurrent Scores - Blue: \(blueScore), Red: \(redScore)")
        print("---------------------------\n")
    }
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
