//
//  AddRoundViewController+UISetup.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import AVFoundation
import FlagKit
import UIKit

extension AddRoundViewController {

    // MARK: - UI Setup
    func setupUI() {
        guard let fight = fight,
            let blueFighter = blueFighter,
            let redFighter = redFighter,
            let event = event
        else {
            print("Missing fight data")
            return
        }

        // Set match information
        matchNumber.text = "\(fight.fightNumber)"
        infoFightLabel.text =
            "\(event.eventName) | \(event.eventType) | \(fight.weightCategory)"

        // Set fighter names
        bluefighterlabel.text =
            "\(blueFighter.firstName) \(blueFighter.lastName)"
        redfighterlabel.text = "\(redFighter.firstName) \(redFighter.lastName)"

        // Set fighter countries
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

        // Setup pause/resume button
        setupPauseResumeButton()
    }

    // MARK: - Progress View Setup
    func setupProgressView() {
        // Initialize the progressView
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0.0
        progressView.isHidden = true  // Hidden by default

        // Add progressView to the main view
        view.addSubview(progressView)

        // Configure constraints to position progressView below `videoPlayerContainerView`
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 0),
            progressView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: 0),
            progressView.topAnchor.constraint(
                equalTo: blueiconescored.topAnchor, constant: 15),
            progressView.heightAnchor.constraint(equalToConstant: 4),
        ])
    }

    // MARK: - Score Management
    func manageScores() {
        calculateScores()
        updateScoreLabels()
        updateGamjeonLabels()
        updateHitsLabels()
        loadExistingRounds()
    }

    private func calculateScores() {
        guard let currentRound = currentRound else { return }

        blueScore = calculateScore(for: .blue, in: currentRound)
        redScore = calculateScore(for: .red, in: currentRound)
    }

    func loadExistingRounds() {
        guard let fight = fight else { return }

        FirebaseService.shared.getAllRoundsForFight(fight) {
            [weak self] result in
            switch result {
            case .success(let fetchedRounds):
                self?.rounds = fetchedRounds
                self?.updateRoundWinIndicators()
            case .failure(let error):
                print("Failed to fetch rounds: \(error.localizedDescription)")
            }
        }
    }

    private func calculateScore(for color: FighterColor, in round: Round) -> Int
    {
        let directPoints = round.actions.filter {
            $0.color == color && $0.actionType != .gamJeon
                && ($0.isActive != nil)
        }.reduce(0) { $0 + $1.points }
        let opponentColor: FighterColor = color == .blue ? .red : .blue
        let gamjeonPoints = round.actions.filter {
            $0.color == opponentColor && $0.actionType == .gamJeon
                && ($0.isActive != nil)
        }.count
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
            guard let self = self, let currentRound = self.currentRound else {
                return
            }
            self.bluegamjeonlabel.text =
                "\(self.countGamjeons(for: .blue, in: currentRound))"
            self.redgamjeonlabel.text =
                "\(self.countGamjeons(for: .red, in: currentRound))"
        }
    }

    private func countGamjeons(for color: FighterColor, in round: Round) -> Int
    {
        round.actions.filter {
            $0.color == color && $0.actionType == .gamJeon
                && ($0.isActive != nil)
        }.count
    }

    private func updateHitsLabels() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let currentRound = self.currentRound else {
                return
            }
            self.bluehitslabel.text = "\(currentRound.blueHits)"
            self.redhitslabel.text = "\(currentRound.redHits)"
        }
    }

    // MARK: - Debug Helpers
    func printCurrentRoundActions() {
        guard let currentRound = currentRound else {
            print("No current round available")
            return
        }

        print("\n--- Current Round Actions ---")
        print("Round Number: \(currentRound.roundNumber)")
        print("Total Actions: \(currentRound.actions.count)")
        print(
            "Active Actions: \(currentRound.actions.filter { $0.isActive ?? true}.count)"
        )

        for (index, action) in currentRound.actions.enumerated() {
            print("\nAction \(index + 1):")
            print("  Type: \(action.actionType)")
            print("  Color: \(action.color)")
            print("  Is Active: \(String(describing: action.isActive))")
            print("  Timestamp: \(action.timeStamp)")
            if let technique = action.technique {
                print("  Technique: \(technique)")
            }
            print("  Points: \(action.points)")
            if let gamjeonType = action.gamjeonType {
                print("  Gamjeon Type: \(gamjeonType)")
            }
        }

        print("\nCurrent Scores - Blue: \(blueScore), Red: \(redScore)")
        print("---------------------------\n")
    }

    // MARK: - Alert Helper
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil))

        if let popoverController = alertController.popoverPresentationController
        {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(
                x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0,
                height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Private Helper Methods
    private func setupPauseResumeButton() {
        pauseResumeButton.setTitle("Pause", for: .normal)
        pauseResumeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 40)
        pauseResumeButton.titleLabel?.transform = CGAffineTransform(
            rotationAngle: -CGFloat.pi / 2)
        pauseResumeButton.titleLabel?.numberOfLines = 1
        pauseResumeButton.titleLabel?.lineBreakMode = .byClipping
        pauseResumeButton.contentVerticalAlignment = .center
        pauseResumeButton.contentHorizontalAlignment = .center
    }
}
