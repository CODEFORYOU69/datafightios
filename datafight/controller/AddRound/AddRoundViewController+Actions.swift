//
//  AddRoundViewController+Actions.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import UIKit
import AVFoundation


extension AddRoundViewController {
    
    func handleActionSelection(category: String, value: String) {
        guard var action = currentAction else { return }
        
        switch category {
        case "Technique":
            action.technique = Technique(rawValue: value)
            action.actionType = .kick // ou .punch selon la technique
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
    func updateScores(with action: Action) {
        switch action.actionType {
        case .gamJeon:
            // Pour un gamjeon, ajoutez un point à l'adversaire
            if action.color == .blue {
                redScore += 1
            } else {
                blueScore += 1
            }
        default:
            // Pour les autres types d'actions, ajoutez les points au combattant qui a effectué l'action
            if action.color == .blue {
                blueScore += action.points
            } else {
                redScore += action.points
            }
        }
    }

    
    func finalizeAction(_ action: Action) {
        print("Finalisation de l'action")
        
        // Obtenez le temps actuel de la vidéo en secondes
        let videoTime = CMTimeGetSeconds(videoPlayerView.player?.currentTime() ?? CMTime.zero)
        let videoTimeCM = CMTime(seconds: videoTime, preferredTimescale: 600)
        
        // Mettre à jour l'action avec le timestamp de la vidéo
        var updatedAction = action
        updatedAction.videoTimestamp = videoTime
        
        seekVideo(to: videoTimeCM)
        
        // Créer un nouveau round si nécessaire
        if currentRound == nil {
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
                roundNumber: (fight.roundIds?.count ?? 0) + 1,
                chronoDuration: chronoDuration,
                duration: 0, // Sera mis à jour à la fin du round
                roundTime: roundTime,
                blueFighterId: fight.blueFighterId,
                redFighterId: fight.redFighterId,
                actions: [],
                videoReplays: [],
                isSynced: false
            )
        }
        
        // Ajouter l'action au round actuel
        currentRound?.actions.append(updatedAction)
        
        // Sauvegarder l'action dans Firebase
        FirebaseService.shared.saveAction(updatedAction, for: fight!, videoTimestamp: videoTime) { result in
            switch result {
            case .success:
                print("Action saved successfully in Firebase")
            case .failure(let error):
                print("Failed to save action in Firebase: \(error.localizedDescription)")
            }
        }

        // Ajouter l'icône pour l'action
        addActionIcon(for: updatedAction)
        
        // Mettre à jour les scores et l'interface utilisateur
        updateScores(with: updatedAction)
        updateUI()
        resumeTimer()
        
        // Vérifier si le round doit se terminer (par exemple, si un KO a été enregistré)
        checkRoundEndConditions(updatedAction)
    }
    
    func undoLastAction() {
        guard var currentRound = currentRound, !currentRound.actions.isEmpty else {
            print("No actions to undo")
            return
        }
        
        let lastAction = currentRound.actions.removeLast()
        print("Removed action: \(lastAction)")
        
        // Mettre à jour le round actuel
        self.currentRound = currentRound
        
        // Mettre à jour le score
        updateScores()
        
        // Forcer une mise à jour immédiate de l'interface utilisateur
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
            self?.removeLastActionIcon()
        }
        
        showAlert(title: "Action Undone", message: "The last action has been removed.")
    }

    func addActionIcon(for action: Action, videoReplay: VideoReplay? = nil) {
        let iconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        iconView.contentMode = .scaleAspectFit

        let colorPrefix = action.color == .blue ? "BLUE" : "RED"
        
        // Définir l'image en fonction de l'action
        switch action.actionType {
        case .kick, .punch:
            let points = action.technique?.points ?? 0
            switch points {
            case 1:
                iconView.image = UIImage(named: "\(colorPrefix)PUNCH")
            case 2:
                iconView.image = UIImage(named: "\(colorPrefix)HOGU")
            case 3:
                iconView.image = UIImage(named: "\(colorPrefix)HELMET")
            case 4:
                iconView.image = combineImages(baseImage: "\(colorPrefix)HOGU", overlayImage: "arrow.2.circlepath", overlayTint: action.color == .blue ? .blue : .red)
            case 5:
                iconView.image = combineImages(baseImage: "\(colorPrefix)HELMET", overlayImage: "arrow.2.circlepath", overlayTint: action.color == .blue ? .blue : .red)
            default:
                return
            }
        case .gamJeon:
            iconView.image = UIImage(named: "gamjeon")
        case .videoReplay:
            iconView.image = UIImage(systemName: videoReplay?.wasAccepted ?? false ? "video.fill" : "video.slash.fill")
        
        }

        // Ajouter l'icône à la vue principale
        IconActionRegistered.addSubview(iconView)

        // Déterminer la position X en fonction du nombre d'icônes déjà présentes
        let xPosition = CGFloat(IconActionRegistered.subviews.count - 1) * 40 // Déplacement horizontal
        iconView.frame.origin.x = xPosition
        
        // Déterminer la position Y en fonction de la couleur
        let yPosition = action.color == .blue ? 10 : IconActionRegistered.frame.height - 40 // Décalage vertical pour les rouges
        iconView.frame.origin.y = yPosition

        // Ajouter un geste de tap pour naviguer dans la vidéo
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(actionIconTapped(_:)))
        iconView.isUserInteractionEnabled = true
        iconView.addGestureRecognizer(tapGesture)

        // Stocker l'action dans le tag de l'icône (pour la récupérer plus tard)
        iconView.tag = action.id.hashValue
    }

    // Handler pour le tap sur une icône
    @objc func actionIconTapped(_ sender: UITapGestureRecognizer) {
        guard let iconView = sender.view as? UIImageView else { return }
        
        // Cherchez l'action correspondante par son id (stockée dans le tag)
        if let action = currentRound?.actions.first(where: { $0.id.hashValue == iconView.tag }) {
            let videoTime = CMTime(seconds: action.videoTimestamp, preferredTimescale: 600)
            seekVideo(to: videoTime)  // Déplacez la vidéo à ce moment
        }
    }
    // Fonction utilitaire pour combiner deux images
    private func combineImages(baseImage: String, overlayImage: String, overlayTint: UIColor) -> UIImage? {
        guard let base = UIImage(named: baseImage),
              let overlay = UIImage(systemName: overlayImage)?.withTintColor(overlayTint, renderingMode: .alwaysOriginal) else {
            return nil
        }
        
        let size = CGSize(width: 30, height: 30)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        base.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
        overlay.draw(in: CGRect(x: 15, y: 15, width: 15, height: 15)) // Superposition en bas à droite
        
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return combinedImage
    }
}

