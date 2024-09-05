//
//  actionwheelForIvr.swift
//  datafight
//
//  Created by younes ouasmi on 03/09/2024.
//

import UIKit

extension AddRoundViewController {

    func handleVideoReplayRequest(for color: FighterColor, sourceView: UIView) {
        pauseTimer() // Ajout de cette ligne pour mettre en pause la vidéo et le timer
        
        guard let fight = fight else { return }
        
        if fight.usedVideoReplay(for: color) {
            showAlert(title: "Video Replay Unavailable", message: "This fighter has already used their video replay for this fight.")
            return
        }
        
        let alertController = UIAlertController(title: "Video Replay Request", message: "Is the video request accepted?", preferredStyle: .alert)
        
        let acceptAction = UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
            self?.processAcceptedVideoReplay(for: color, sourceView: sourceView)
        }
        
        
        alertController.addAction(acceptAction)
        
        let rejectAction = UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            self?.processRejectedVideoReplay(for: color)
            self?.resumeTimer()
        }
        alertController.addAction(rejectAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func processAcceptedVideoReplay(for color: FighterColor, sourceView: UIView) {
        let videoReplay = VideoReplay(
            id: UUID().uuidString,
            requestedByFighterId: color == .blue ? fight?.blueFighterId ?? "" : fight?.redFighterId ?? "",
            requestedByColor: color,
            timeStamp: chronoDuration - remainingTime,
            wasAccepted: true
        )
        
        currentRound?.videoReplays.append(videoReplay)
        
        
        let videoReplayAction = Action(
            id: UUID().uuidString,
            fighterId: videoReplay.requestedByFighterId,
            color: color,
            actionType: .videoReplay,
            technique: nil,
            limbUsed: nil,
            actionZone: nil,
            timeStamp: videoReplay.timeStamp,
            situation: nil,
            gamjeonType: nil,
            guardPosition: nil,
            videoTimestamp: videoReplay.timeStamp
            
        )
        addActionIcon(for: videoReplayAction, videoReplay: videoReplay)
        
        let actionSheet = UIAlertController(title: "Video Replay Action", message: "What action do you want to take?", preferredStyle: .actionSheet)
        
        let addGamjeonAction = UIAlertAction(title: "Add Gamjeon to Opponent", style: .default) { [weak self] _ in
            self?.addGamjeonToOpponent(of: color)
        }
        actionSheet.addAction(addGamjeonAction)
        
        let addActionAction = UIAlertAction(title: "Add Action", style: .default) { [weak self] _ in
            self?.showActionWheel(for: color ,isIVRRequest: true)
        }
        actionSheet.addAction(addActionAction)
        
        let removeGamjeonAction = UIAlertAction(title: "Remove Gamjeon from Requester", style: .default) { [weak self] _ in
            self?.removeGamjeonFromRequester(color)
        }
        actionSheet.addAction(removeGamjeonAction)
        
        let deleteActionAction = UIAlertAction(title: "Delete Recent Action", style: .default) { [weak self] _ in
            self?.showRecentActionsForDeletion()
        }
        actionSheet.addAction(deleteActionAction)
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
            popoverController.permittedArrowDirections = [.up, .down]
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    func processRejectedVideoReplay(for color: FighterColor) {
        let videoReplay = VideoReplay(
            id: UUID().uuidString,
            requestedByFighterId: color == .blue ? fight?.blueFighterId ?? "" : fight?.redFighterId ?? "",
            requestedByColor: color,
            timeStamp: chronoDuration - remainingTime,
            wasAccepted: false
        )
        
        currentRound?.videoReplays.append(videoReplay)
        fight?.markVideoReplayAsUsed(for: color)
        
        let videoReplayAction = Action(
            id: UUID().uuidString,
            fighterId: videoReplay.requestedByFighterId,
            color: color,
            actionType: .videoReplay,
            technique: nil,
            limbUsed: nil,
            actionZone: nil,
            timeStamp: videoReplay.timeStamp,
            situation: .attack,
            gamjeonType: nil,
            guardPosition: nil,
            videoTimestamp: videoReplay.timeStamp
            
        )
        addActionIcon(for: videoReplayAction, videoReplay: videoReplay)
        
        // Disable the IVR button for this color
        if color == .blue {
            blueIvr.isEnabled = false
        } else {
            redIvr.isEnabled = false
        }
        
        showAlert(title: "Video Replay Rejected", message: "The video replay request has been rejected. This fighter cannot request another video replay in this fight.")
    }
    
    func addGamjeonToOpponent(of color: FighterColor) {
        let opponentColor = color == .blue ? FighterColor.red : FighterColor.blue
        let timeStamp = chronoDuration - remainingTime
        
        let initialGamjeonAction = Action(
            id: UUID().uuidString,
            fighterId: opponentColor == .blue ? fight?.blueFighterId ?? "" : fight?.redFighterId ?? "",
            color: opponentColor,
            actionType: .gamJeon,
            technique: nil,
            limbUsed: nil,
            actionZone: nil,
            timeStamp: chronoDuration - remainingTime,
            situation: nil,
            gamjeonType: nil,
            guardPosition: nil,
            videoTimestamp: timeStamp
        )
        
        let pickerFrame = CGRect(x: 0, y: 0, width: view.bounds.width * 0.4, height: view.bounds.height * 0.5)
        let actionPicker = ActionPickerView(
            frame: pickerFrame,
            initialAction: initialGamjeonAction,
            points: 1,
            isIVRRequest: true,
            onComplete: { [weak self] completedAction in
                guard let self = self else { return }
                if let completedAction = completedAction {
                    self.currentRound?.actions.append(completedAction)
                    // Ajuster le score
                    if completedAction.color == .blue {
                        self.redScore += 1
                    } else {
                        self.blueScore += 1
                    }
                    self.manageScores()
                }
                self.actionPicker?.removeFromSuperview()
                self.actionPicker = nil
                self.checkForMoreActions(sourceView: self.view)
            },
            onCancel: { [weak self] in
                self?.actionPicker?.removeFromSuperview()
                self?.actionPicker = nil
                self?.resumeTimer()
            },
            onUndo: { [weak self] in
                // Handle undo if needed
            }
        )
        
        actionPicker.center = view.center
        actionPicker.layer.cornerRadius = 20
        actionPicker.layer.masksToBounds = true
        
        view.addSubview(actionPicker)
        self.actionPicker = actionPicker
    }
    
    func showActionWheel(for color: FighterColor, isIVRRequest: Bool) {
        let timeStamp = chronoDuration - remainingTime
        
        let action = Action(
            id: UUID().uuidString,
            fighterId: color == .blue ? fight?.blueFighterId ?? "" : fight?.redFighterId ?? "",
            color: color,
            actionType: .gamJeon,
            technique: nil,
            limbUsed: nil,
            actionZone: nil,
            timeStamp: chronoDuration - remainingTime,
            situation: .attack,
            gamjeonType: nil,
            guardPosition: nil,
            videoTimestamp: timeStamp
            
        )
        
        showActionDetailsInterface(for: action, points: 0, isIVRRequest: isIVRRequest)  // Passez isIVRRequest ici
    }
    
    func removeGamjeonFromRequester(_ color: FighterColor) {
        // Afficher les gamJeons actifs avant la désactivation
        print("Active GamJeons before removal:")
        if let activeGamJeons = currentRound?.actions.filter({ $0.actionType == .gamJeon && $0.isActive }) {
            for (index, gamJeon) in activeGamJeons.enumerated() {
                print("GamJeon \(index + 1): Color: \(gamJeon.color), Timestamp: \(gamJeon.timeStamp)")
            }
        } else {
            print("No active gamJeons found")
        }
        
        // Désactiver le dernier gamJeon actif du requérant et ajuster le score
        if let index = currentRound?.actions.lastIndex(where: { $0.color == color && $0.actionType == .gamJeon && $0.isActive }) {
            currentRound?.actions[index].isActive = false
            print("GamJeon deactivated for color: \(color)")
            
            // Ajuster le score
            switch color {
            case .blue:
                redScore -= 1
                print("Removed 1 point from Red score")
            case .red:
                blueScore -= 1
                print("Removed 1 point from Blue score")
            }
        } else {
            print("No active gamJeon found to deactivate for color: \(color)")
        }
        
        // Afficher les gamJeons actifs après la désactivation
        print("Active GamJeons after removal:")
        if let activeGamJeons = currentRound?.actions.filter({ $0.actionType == .gamJeon && $0.isActive }) {
            for (index, gamJeon) in activeGamJeons.enumerated() {
                print("GamJeon \(index + 1): Color: \(gamJeon.color), Timestamp: \(gamJeon.timeStamp)")
            }
        } else {
            print("No active gamJeons found")
        }
        
        // Afficher les scores mis à jour
        print("Updated scores - Blue: \(blueScore), Red: \(redScore)")
        
        manageScores()
        checkForMoreActions(sourceView: self.view)
    }
    
    func deleteAction(_ action: Action) {
        if let index = currentRound?.actions.firstIndex(where: { $0.id == action.id }) {
            // Désactiver l'action au lieu de la supprimer
            currentRound?.actions[index].isActive = false
            
            print("Action deactivated: \(action.actionType) for color: \(action.color)")
            
            // Mettre à jour le score
            updateScoreAfterDeactivation(of: action)
            
            // Mettre à jour l'interface utilisateur
            manageScores()
            
            // Mettre à jour l'affichage de l'icône de l'action si nécessaire
            updateActionIcon(for: action)
            
            // Vérifier s'il y a d'autres actions à effectuer
            checkForMoreActions(sourceView: self.view)
        }
    }
    
    func updateScoreAfterDeactivation(of action: Action) {
        switch action.actionType {
        case .gamJeon:
            // Si c'était un gamjeon, on retire le point à l'adversaire
            if action.color == .blue {
                redScore -= 1
                print("Removed 1 point from Red score")
            } else {
                blueScore -= 1
                print("Removed 1 point from Blue score")
            }
        case .kick, .punch:
            // Si c'était un coup marquant, on retire les points au combattant
            if action.color == .blue {
                blueScore -= action.points
                print("Removed \(action.points) points from Blue score")
            } else {
                redScore -= action.points
                print("Removed \(action.points) points from Red score")
            }
        case  .videoReplay:
            // Ces types d'actions n'affectent pas le score
            print("No score change for \(action.actionType)")
        }
        
        print("Scores after deactivation - Blue: \(blueScore), Red: \(redScore)")
    }
    
    func updateActionIcon(for action: Action) {
        // Chercher l'icône correspondant à l'action dans IconActionRegistered
        if let iconView = IconActionRegistered.subviews.first(where: { $0.tag == action.id.hashValue }) {
            // Mettre à jour l'opacité de l'icône en fonction du statut isActive de l'action
            UIView.animate(withDuration: 0.3) {
                iconView.alpha = action.isActive ? 1.0 : 0.5
            }
            
            print("Updated icon for action: \(action.actionType), isActive: \(action.isActive)")
        } else {
            print("Icon not found for action: \(action.actionType)")
        }
    }
    
    func showRecentActionsForDeletion() {
        let actionSheet = UIAlertController(title: "Deactivate Recent Action", message: "Select an action to deactivate", preferredStyle: .actionSheet)
        
        let recentActions = Array(currentRound?.actions.filter { $0.isActive }.suffix(3) ?? [])
        
        for action in recentActions.reversed() {
            let actionTitle = "\(action.color.rawValue) - \(action.actionType.rawValue)"
            let deleteAction = UIAlertAction(title: actionTitle, style: .destructive) { [weak self] _ in
                self?.deleteAction(action)
            }
            actionSheet.addAction(deleteAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        // Vérifier si nous sommes sur un iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Sur iPad, nous devons présenter l'action sheet comme un popover
            if let popoverController = actionSheet.popoverPresentationController {
                // Utiliser le centre de la vue comme source du popover
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func checkForMoreActions(sourceView: UIView) {
        let alertController = UIAlertController(title: "More Actions", message: "Do you want to perform another action for this video replay?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            if let color = self?.currentAction?.color {
                self?.processAcceptedVideoReplay(for: color, sourceView: sourceView)
            }
        }
        alertController.addAction(yesAction)
        
        let noAction = UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
            self?.finalizeVideoReplay()
        }
        alertController.addAction(noAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
            popoverController.permittedArrowDirections = [.up, .down]
        }
        
        present(alertController, animated: true, completion: nil)
    }
    func finalizeVideoReplay() {
        
        manageScores()
        resumeTimer()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
