//
//  AddRoundViewController+Actions.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import AVFoundation
import UIKit

extension AddRoundViewController {

    // MARK: - Action Recording

    /// Records a new action for a fighter
    func recordAction(
        color: FighterColor, zone: Zone, situation: CombatSituation? = nil,
        points: Int
    ) {
        pauseTimer()

        let currentTime = videoPlayerView.player?.currentTime() ?? CMTime.zero
        let timestamp = CMTimeGetSeconds(currentTime)

        // Create a new action
        let newAction = Action(
            id: UUID().uuidString,
            fighterId: color == .blue
                ? fight?.blueFighterId ?? "" : fight?.redFighterId ?? "",
            color: color,
            actionType: .kick,  // To be determined based on the interaction
            technique: nil,  // To be determined later
            limbUsed: nil,  // To be determined later
            actionZone: zone,
            timeStamp: chronoDuration - remainingTime,
            situation: situation ?? .attack,
            gamjeonType: nil,
            guardPosition: nil,  // To be determined later
            videoTimestamp: timestamp,
            isActive: true,
            chronoTimestamp: 0
        )

        showActionDetailsInterface(
            for: newAction, points: points, isIVRRequest: isIVRRequest)
    }

    // MARK: - Video Marker

    /// Adds a marker at the current time in the video progress bar
    func addMarkerAtCurrentTime() {
        guard let player = videoPlayerView.player else { return }

        // Calculate the position percentage on the progress bar
        let currentTime = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 1
        let percentage = CGFloat(currentTime / duration)

        // Create a marker view
        let markerView = UIView()
        markerView.backgroundColor = .red  // Color of the marker bar
        markerView.translatesAutoresizingMaskIntoConstraints = false

        videoProgressView.addSubview(markerView)

        // Set size and position constraints for the marker
        NSLayoutConstraint.activate([
            markerView.widthAnchor.constraint(equalToConstant: 2),  // Width of the bar
            markerView.heightAnchor.constraint(
                equalTo: videoProgressView.heightAnchor, multiplier: 1.5),  // 50% taller than the progress bar
            markerView.centerYAnchor.constraint(
                equalTo: videoProgressView.centerYAnchor),

            // Center the bar at the calculated position
            markerView.centerXAnchor.constraint(
                equalTo: videoProgressView.leadingAnchor,
                constant: percentage * videoProgressView.bounds.width),
        ])
    }

    // MARK: - Action Handling

    /// Handles the selection of action details
    func handleActionSelection(category: String, value: String) {
        guard var action = currentAction else { return }

        switch category {
        case "Technique":
            action.technique = Technique(rawValue: value)
            action.actionType = .kick  // or .punch depending on the technique
        case "Limb":
            action.limbUsed = Limb(rawValue: value)
        case "Guard":
            action.guardPosition = GuardPosition(rawValue: value)
            finalizeAction(action)
        default:
            break
        }

        currentAction = action
    }

    /// Updates scores based on the given action
    func updateScores(with action: Action) {
        switch action.actionType {
        case .gamJeon:
            // For a gamjeon, add a point to the opponent
            if action.color == .blue {
                redScore += 1
            } else {
                blueScore += 1
            }
        default:
            // For other action types, add points to the fighter who performed the action
            if action.color == .blue {
                blueScore += action.points
            } else {
                redScore += action.points
            }
        }
    }

    // MARK: - Action Finalization

    /// Finalizes an action and updates the game state
    func finalizeAction(_ action: Action) {
        print("Finalizing the action")

        // Get the current video time in seconds
        let videoTime = CMTimeGetSeconds(
            videoPlayerView.player?.currentTime() ?? CMTime.zero)
        let videoTimeCM = CMTime(seconds: videoTime, preferredTimescale: 600)

        print("Current video time: \(videoTime)")

        // Update the action with the video timestamp
        var updatedAction = action
        updatedAction.videoTimestamp = videoTime
        updatedAction.chronoTimestamp = action.chronoTimestamp  // Chrono entered by the user

        print(
            "Adding action with video timestamp: \(updatedAction.videoTimestamp), chrono timestamp: \(String(describing: updatedAction.chronoTimestamp))"
        )

        seekVideo(to: videoTimeCM)

        // Create a new round if necessary
        if currentRound == nil {
            createNewRound()
        }

        // Add the action to the current round
        currentRound?.actions.append(updatedAction)

        // Save the action to Firebase
        saveActionToFirebase(updatedAction, videoTime: videoTime)

        // Add the icon for the action
        addActionIcon(for: updatedAction)

        // Update scores and user interface
        updateScores(with: updatedAction)
        manageScores()
        resumeTimer()
    }

    // MARK: - Undo Action

    /// Undoes the last action
    func undoLastAction() {
        guard var currentRound = currentRound, !currentRound.actions.isEmpty
        else {
            print("No actions to undo")
            return
        }

        let lastAction = currentRound.actions.removeLast()
        print("Removed action: \(lastAction)")

        // Update the current round
        self.currentRound = currentRound

        // Update the score
        updateScores()

        // Force an immediate update of the user interface
        DispatchQueue.main.async { [weak self] in
            self?.manageScores()
            self?.removeLastActionIcon()
        }

        showAlert(
            title: "Action Undone", message: "The last action has been removed."
        )
    }

    // MARK: - Action Icon Management

    /// Adds an icon for the given action
    func addActionIcon(for action: Action, videoReplay: VideoReplay? = nil) {
        let iconView = UIImageView(
            frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        iconView.contentMode = .scaleAspectFit

        let colorPrefix = action.color == .blue ? "BLUE" : "RED"

        // Set the image based on the action
        switch action.actionType {
        case .kick, .punch:
            setKickPunchIcon(
                for: action, colorPrefix: colorPrefix, iconView: iconView)
        case .gamJeon:
            iconView.image = UIImage(named: "gamjeon")
        case .videoReplay:
            iconView.image = UIImage(
                systemName: videoReplay?.wasAccepted ?? false
                    ? "video.fill" : "video.slash.fill")
        }

        // Add the icon to the main view
        IconActionRegistered.addSubview(iconView)

        // Determine the X position based on the number of icons already present
        let xPosition = CGFloat(IconActionRegistered.subviews.count - 1) * 40  // Horizontal displacement
        iconView.frame.origin.x = xPosition

        // Determine the Y position based on the color
        let yPosition =
            action.color == .blue
            ? 10 : IconActionRegistered.frame.height - 40  // Vertical offset for reds
        iconView.frame.origin.y = yPosition

        // Add a tap gesture to navigate in the video
        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(actionIconTapped(_:)))
        iconView.isUserInteractionEnabled = true
        iconView.addGestureRecognizer(tapGesture)

        // Store the action in the icon's tag (to retrieve it later)
        iconView.tag = action.id.hashValue
    }

    // Handler for tapping on an icon
    @objc func actionIconTapped(_ sender: UITapGestureRecognizer) {
        guard let iconView = sender.view as? UIImageView else { return }

        // Look for the corresponding action by its id (stored in the tag)
        if let action = currentRound?.actions.first(where: {
            $0.id.hashValue == iconView.tag
        }) {
            let videoTime = CMTime(
                seconds: action.videoTimestamp, preferredTimescale: 600)
            seekVideo(to: videoTime)  // Move the video to this moment
        }
    }

    // MARK: - Helper Methods

    /// Utility function to combine two images
    private func combineImages(
        baseImage: String, overlayImage: String, overlayTint: UIColor
    ) -> UIImage? {
        guard let base = UIImage(named: baseImage),
            let overlay = UIImage(systemName: overlayImage)?.withTintColor(
                overlayTint, renderingMode: .alwaysOriginal)
        else {
            return nil
        }

        let size = CGSize(width: 30, height: 30)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        base.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
        overlay.draw(in: CGRect(x: 15, y: 15, width: 15, height: 15))  // Overlay at the bottom right

        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return combinedImage
    }

    /// Sets the appropriate icon for kick or punch actions
    private func setKickPunchIcon(
        for action: Action, colorPrefix: String, iconView: UIImageView
    ) {
        let points = action.technique?.points ?? 0
        switch points {
        case 1:
            iconView.image = UIImage(named: "\(colorPrefix)PUNCH")
        case 2:
            iconView.image = UIImage(named: "\(colorPrefix)HOGU")
        case 3:
            iconView.image = UIImage(named: "\(colorPrefix)HELMET")
        case 4:
            iconView.image = combineImages(
                baseImage: "\(colorPrefix)HOGU",
                overlayImage: "arrow.2.circlepath",
                overlayTint: action.color == .blue ? .blue : .red)
        case 5:
            iconView.image = combineImages(
                baseImage: "\(colorPrefix)HELMET",
                overlayImage: "arrow.2.circlepath",
                overlayTint: action.color == .blue ? .blue : .red)
        default:
            return
        }
    }

    /// Creates a new round
    private func createNewRound() {
        guard let fight = fight else {
            print("Error: Fight is not set")
            return
        }

        guard let roundTime = currentRound?.roundTime else {
            print("Error: Round time is not set")
            return
        }

        currentRound = Round(
            fightId: fight.id ?? "",
            creatorUserId: fight.creatorUserId,
            roundNumber: (fight.roundIds?.count ?? 0) + 1,
            chronoDuration: chronoDuration,
            duration: 0,  // Will be updated at the end of the round
            roundTime: roundTime,
            blueFighterId: fight.blueFighterId,
            redFighterId: fight.redFighterId,
            actions: [],
            videoReplays: [],
            isSynced: false
        )
    }

    /// Saves the action to Firebase
    private func saveActionToFirebase(_ action: Action, videoTime: Double) {
        FirebaseService.shared.saveAction(
            action, for: fight!, videoTimestamp: videoTime
        ) { result in
            switch result {
            case .success:
                print("Action saved successfully in Firebase")
            case .failure(let error):
                print(
                    "Failed to save action in Firebase: \(error.localizedDescription)"
                )
            }
        }
    }
}
