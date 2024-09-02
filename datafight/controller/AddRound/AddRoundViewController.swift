//
//  AddRoundViewController.swift
//  datafight
//
//  Created by younes ouasmi on 23/08/2024.
//

import UIKit
import FlagKit
import CoreMedia
import AVFoundation
import AVKit
import MobileCoreServices
import FirebaseStorage
import UniformTypeIdentifiers



class AddRoundViewController: UIViewController {
    @IBOutlet weak var infoFightLabel: UILabel!
    @IBOutlet weak var bluefighterlabel: UILabel!
    @IBOutlet weak var redfighterlabel: UILabel!
    @IBOutlet weak var matchNumber: UILabel!
    @IBOutlet weak var blueflagimage: UIImageView!
    @IBOutlet weak var bluecountrylabel: UILabel!
    @IBOutlet weak var redflagimage: UIImageView!
    @IBOutlet weak var redcountrylabel: UILabel!
    @IBOutlet weak var bluescore: UILabel!
    @IBOutlet weak var redscore: UILabel!
    @IBOutlet weak var bluegamjeonlabel: UILabel!
    @IBOutlet weak var bluewinningroundlabel: UILabel!
    @IBOutlet weak var bluehitslabel: UILabel!
    @IBOutlet weak var redhitslabel: UILabel!
    @IBOutlet weak var redwinningroundlabel: UILabel!
    @IBOutlet weak var redgamjeonlabel: UILabel!
    @IBOutlet weak var blueiconescored: UIView!
    @IBOutlet weak var rediconescored: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var pauseResumeButton: UIButton!
    @IBOutlet weak var gestureZ1: UIImageView!
    @IBOutlet weak var gestureZ2: UIImageView!
    @IBOutlet weak var gestureZ3: UIImageView!
    @IBOutlet weak var blueIvr: UIButton!
    @IBOutlet weak var redIvr: UIButton!
    @IBOutlet weak var roundNumberLabel: UILabel!


    @IBOutlet weak var IconActionRegistered: UIView!
    @IBOutlet weak var videoPlayerContainerView: UIView!
    var progressView: UIProgressView!
    @IBOutlet weak var videoProgressView: UIProgressView!
    @IBAction func endRoundButtonTapped(_ sender: UIButton) {
        endRound()
    }




    @IBAction func skipBackwardButtonTapped(_ sender: UIButton) {
           skipTime(by: -10)
       }

       @IBAction func skipForwardButtonTapped(_ sender: UIButton) {
           skipTime(by: 10)
       }
    func skipTime(by seconds: Double) {
           guard let player = videoPlayerView.player else { return }
           let currentTime = player.currentTime().seconds
           let newTime = max(0, currentTime + seconds)
           
           seekVideo(to: CMTime(seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
           remainingTime = chronoDuration - newTime
           updateTimerLabel()
       }
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
        undoLastAction()
    }
    
    @IBAction func setTimeButtonTapped(_ sender: UIButton) {
        showSetTimeModal()
    }
    
    
    var fight: Fight?
    var blueFighter: Fighter?
    var redFighter: Fighter?
    var event: Event?
    var chronoDuration: TimeInterval = 120 // 2 minutes par défaut
    var timer: Timer?
    var remainingTime: TimeInterval = 0
    var isPaused: Bool = false
    private var actionWheel: ActionWheelView!
    var currentAction: Action?
    var currentRound: Round?
    var blueScore: Int = 0
    var redScore: Int = 0
    var isIVRRequest: Bool = false

    var currentRoundNumber: Int = 1

    func updateRoundNumberLabel() {
        roundNumberLabel.text = "\(currentRoundNumber)"
    }
    private var actionPicker: ActionPickerView?
    var videoPlayerView: VideoPlayerView!
     var videoTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupVideoPlayer()
        requestRoundTime()
        setupZoneGestures()
        setupProgressView()
        setCurrentRoundNumber()
           updateRoundNumberLabel()
    }
    func setCurrentRoundNumber() {
        guard let fight = fight else {
            currentRoundNumber = 1
            return
        }
        
        currentRoundNumber = (fight.roundIds?.count ?? 0) + 1
        print("Current round number set to: \(currentRoundNumber)")
    }
    func requestRoundTime() {
        let alertController = UIAlertController(title: "Round Duration", message: "Enter the duration of the round (in minutes):", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Minutes"
            textField.keyboardType = .numberPad
        }
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if let minutesString = alertController.textFields?.first?.text,
               let minutes = Int(minutesString) {
                // Convertir les minutes en secondes pour roundTime
                let roundTimeInSeconds = minutes * 60
                self?.initializeRound(with: roundTimeInSeconds)
            } else {
                // Si aucune valeur n'est entrée, répéter la demande
                self?.requestRoundTime()
            }
        }
        
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }

    func initializeRound(with roundTime: Int) {
        // Initialiser le round ici avec roundTime et ensuite vérifier pour une vidéo
        if let fight = fight {
            currentRound = Round(
                id: nil,  // ou généré automatiquement si nécessaire
                fightId: fight.id ?? "",
                roundNumber: (fight.roundIds?.count ?? 0) + 1,
                chronoDuration: 0,  // Défini plus tard lorsque la vidéo est chargée
                duration: 0,  // Sera mis à jour à la fin du round
                roundTime: roundTime,  // La durée entrée par l'utilisateur
                blueFighterId: fight.blueFighterId,
                redFighterId: fight.redFighterId,
                actions: [],
                videoReplays: [],
                isSynced: false,
                victoryDecision: nil,
                roundWinner: nil
            )
        }
                checkForVideo()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupVideoPlayer()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseVideo()
        
    }
    
    
    func checkForVideo() {
        if let videoURLString = fight?.videoURL, let videoURL = URL(string: videoURLString) {
            print("Video found, setting up video player.")
            setupVideoPlayer(with: videoURL)
        } else {
            print("No video found, prompting for video upload.")
            promptForVideoUpload()
        }
    }
    func setChronoDuration(_ duration: TimeInterval) {
        print("Setting chronoDuration with duration: \(duration)")
        guard let fight = fight else {
            print("Error: fight is nil")
            return
        }
        print("Fight ID: \(fight.id ?? "unknown")")
        print("All roundIds: \(fight.roundIds ?? [])")
        
        guard let videoId = fight.videoId else {
            print("Error: No video ID associated with this fight")
            chronoDuration = duration
            remainingTime = duration
            currentRoundNumber = 1
            updateRoundNumberLabel()
            return
        }
        
        FirebaseService.shared.getVideo(by: videoId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let video):
                print("Successfully fetched video:")
                print("  Video ID: \(video.id)")
                print("  Video Duration: \(video.duration)")
                
                if let lastRoundTimestamp = video.roundTimestamps.last {
                    let lastRoundEndTime = lastRoundTimestamp.end ?? lastRoundTimestamp.start
                    self.chronoDuration = duration - lastRoundEndTime
                    self.remainingTime = self.chronoDuration
                    self.currentRoundNumber = lastRoundTimestamp.roundNumber + 1
                    
                    print("Last round found:")
                    print("  Round Number: \(lastRoundTimestamp.roundNumber)")
                    print("  Round End Time: \(lastRoundEndTime)")
                    print("Set chronoDuration to \(self.chronoDuration) and remainingTime to \(self.remainingTime)")
                    print("Current round number set to: \(self.currentRoundNumber)")
                } else {
                    print("No previous rounds, starting from the beginning of the video")
                    self.chronoDuration = duration
                    self.remainingTime = duration
                    self.currentRoundNumber = 1
                    print("Set chronoDuration and remainingTime to \(duration)")
                    print("Current round number set to: \(self.currentRoundNumber)")
                }
                
                DispatchQueue.main.async {
                    self.updateRoundNumberLabel()
                    self.seekVideo(to: CMTime(seconds: duration - self.chronoDuration, preferredTimescale: 600))
                }
                
            case .failure(let error):
                print("Failed to fetch video: \(error.localizedDescription)")
                self.chronoDuration = duration
                self.remainingTime = duration
                self.currentRoundNumber = 1
                print("Due to error, set both chronoDuration and remainingTime to \(duration)")
                print("Current round number set to: \(self.currentRoundNumber)")
                
                DispatchQueue.main.async {
                    self.updateRoundNumberLabel()
                }
            }
        }
    }
    func setupVideoPlayer() {
        // Créez le VideoPlayerView avec la même taille que la vue conteneur
        videoPlayerView = VideoPlayerView(frame: videoPlayerContainerView.bounds)
        
        // Ajoutez le VideoPlayerView comme sous-vue de la vue conteneur
        videoPlayerContainerView.addSubview(videoPlayerView)
        
        // Ajouter la barre de progression en dessous de la vidéo
        setupVideoProgressView()

        // Configurez les contraintes pour que le VideoPlayerView remplisse complètement la vue conteneur
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoPlayerView.topAnchor.constraint(equalTo: videoPlayerContainerView.topAnchor),
            videoPlayerView.leadingAnchor.constraint(equalTo: videoPlayerContainerView.leadingAnchor),
            videoPlayerView.trailingAnchor.constraint(equalTo: videoPlayerContainerView.trailingAnchor),
            videoPlayerView.bottomAnchor.constraint(equalTo: videoPlayerContainerView.bottomAnchor)
        ])
    }

    func setupVideoProgressView() {
        // Assurez-vous que l'interaction utilisateur est activée
        videoProgressView.isUserInteractionEnabled = true

        // Définir la position z si nécessaire (utile pour assurer la priorité d'affichage)

        // Réinitialiser la barre de progression
        videoProgressView.progress = 0.0
        
        // Ajouter un geste pour détecter les taps sur la barre de progression
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProgressTap(_:)))
        videoProgressView.addGestureRecognizer(tapGesture)
    }

    @objc func handleProgressTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: videoProgressView)
        let percentage = Float(location.x / videoProgressView.bounds.width)
        let duration = videoPlayerView.player?.currentItem?.duration.seconds ?? 0
        let newTime = duration * Double(percentage)
        
        seekVideo(to: CMTime(seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        remainingTime = chronoDuration - newTime
        updateTimerLabel()
    }


    func presentVideoPicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [UTType.movie.identifier]  // Utiliser UTType.movie pour les vidéos
        imagePickerController.videoQuality = .typeMedium
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }

    func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.movie])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    func updateScores() {
        blueScore = calculateScore(for: .blue)
        redScore = calculateScore(for: .red)
    }

    func removeLastActionIcon() {
        IconActionRegistered.subviews.last?.removeFromSuperview()
    }
    func showRoundConfigurationModal() {
        let alertController = UIAlertController(title: "Configure Round", message: "Set the round duration", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Minutes"
            textField.keyboardType = .numberPad
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Seconds"
            textField.keyboardType = .numberPad
        }
        
        let startAction = UIAlertAction(title: "Start Round", style: .default) { [weak self] _ in
            if let minutesString = alertController.textFields?[0].text,
               let secondsString = alertController.textFields?[1].text,
               let minutes = Int(minutesString),
               let seconds = Int(secondsString) {
                let totalDuration = TimeInterval(minutes * 60 + seconds)
                self?.chronoDuration = totalDuration
                self?.remainingTime = totalDuration
                self?.startTimer()
            }
        }
        
        alertController.addAction(startAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func pauseResumeButtonTapped(_ sender: UIButton) {
            if isPaused {
                resumeTimer()
            } else {
                pauseTimer()
            }
        }
    func showSetTimeModal() {
        let alertController = UIAlertController(title: "Set Remaining Time", message: "Enter the remaining time", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Minutes"
            textField.keyboardType = .numberPad
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Seconds"
            textField.keyboardType = .numberPad
        }
        
        let setTimeAction = UIAlertAction(title: "Set Time", style: .default) { [weak self] _ in
            if let minutesString = alertController.textFields?[0].text,
               let secondsString = alertController.textFields?[1].text,
               let minutes = Int(minutesString),
               let seconds = Int(secondsString) {
                let newTime = TimeInterval(minutes * 60 + seconds)
                self?.updateRemainingTime(newTime)
            }
        }
        
        alertController.addAction(setTimeAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }

    func updateRemainingTime(_ newTime: TimeInterval) {
        remainingTime = newTime
        updateTimerLabel()
        
        // Redémarrer le timer avec le nouveau temps
        timer?.invalidate()
        startTimer()
    }
   

    func recordAction(color: FighterColor, zone: Zone, situation: CombatSituation? = nil, points: Int) {
        pauseTimer()
        
        let currentTime = videoPlayerView.player?.currentTime() ?? CMTime.zero
        let timestamp = CMTimeGetSeconds(currentTime)

        let newAction = Action(
            id: UUID().uuidString,
            fighterId: color == .blue ? fight?.blueFighterId ?? "" : fight?.redFighterId ?? "",
            color: color,
            actionType: .kick,  // À déterminer en fonction de l'interaction
            technique: nil,  // À déterminer ultérieurement
            limbUsed: nil,  // À déterminer ultérieurement
            actionZone: zone,
            timeStamp: chronoDuration - remainingTime,
            situation: situation ?? .attack,
            gamjeonType: nil,
            guardPosition: nil,  // À déterminer ultérieurement
            videoTimestamp: timestamp

        )
        
        showActionDetailsInterface(for: newAction, points: points, isIVRRequest: isIVRRequest)

    }
    
    func addMarkerAtCurrentTime() {
        guard let player = videoPlayerView.player else { return }

        // Calculer la position en pourcentage sur la barre de progression
        let currentTime = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 1
        let percentage = CGFloat(currentTime / duration)

        // Créer une vue de marqueur
        let markerView = UIView()
        markerView.backgroundColor = .red // Couleur de la barre de marqueur
        markerView.translatesAutoresizingMaskIntoConstraints = false

        videoProgressView.addSubview(markerView)

        // Définir les contraintes de taille et de position du marqueur
        NSLayoutConstraint.activate([
            markerView.widthAnchor.constraint(equalToConstant: 2), // Largeur de la barre
            markerView.heightAnchor.constraint(equalTo: videoProgressView.heightAnchor, multiplier: 1.5), // 50% plus grande que la barre de progression
            markerView.centerYAnchor.constraint(equalTo: videoProgressView.centerYAnchor),

                   // Centrer la barre à la position calculée
                   markerView.centerXAnchor.constraint(equalTo: videoProgressView.leadingAnchor, constant: percentage * videoProgressView.bounds.width)
        ])
    }

    
    func showActionDetailsInterface(for action: Action, points: Int, isIVRRequest: Bool) {
        actionPicker?.removeFromSuperview()
        
        var actionWithFighterIds = action
        actionWithFighterIds.blueFighterId = fight?.blueFighterId
        actionWithFighterIds.redFighterId = fight?.redFighterId

        let pickerFrame = CGRect(x: 0, y: 0, width: view.bounds.width * 0.4, height: view.bounds.height * 0.5)
        
        let actionPicker = ActionPickerView(
            frame: pickerFrame,
            initialAction: actionWithFighterIds,
            points: points,
            isIVRRequest : isIVRRequest, // Définit IVR request à true pour une requête IVR

            onComplete: { [weak self] completedAction in
                if let completedAction = completedAction {
                    self?.finalizeAction(completedAction)
                } else {
                    self?.resumeTimer()
                }
                self?.actionPicker?.removeFromSuperview()
                self?.actionPicker = nil
            },
            onCancel: { [weak self] in
                // Action à effectuer en cas d'annulation (par exemple, reprendre le timer)
                self?.resumeTimer()
                self?.actionPicker?.removeFromSuperview()
                self?.actionPicker = nil
            },
            onUndo: { [weak self] in
                // Action à effectuer en cas de retour en arrière (Undo)
                // Ici, vous pouvez définir comment gérer le retour arrière, par exemple mettre à jour l'interface ou revenir à une étape précédente
                
            }
            
        )
        
        actionPicker.center = view.center
        actionPicker.layer.cornerRadius = 20
        actionPicker.layer.masksToBounds = true
        actionPicker.alpha = 0
        
        view.addSubview(actionPicker)
        self.actionPicker = actionPicker
        
        UIView.animate(withDuration: 0.3) {
            actionPicker.alpha = 1
        }
        addMarkerAtCurrentTime()
        printCurrentRoundActions()


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

        FirebaseService.shared.getAllRoundsForFight(fight) { [weak self] result in
            switch result {
            case .success(let rounds):
                let blueRoundsWon = rounds.filter { $0.roundWinner == fight.blueFighterId }.count
                let redRoundsWon = rounds.filter { $0.roundWinner == fight.redFighterId }.count

                if blueRoundsWon >= 2 || redRoundsWon >= 2 {
                    let winner = blueRoundsWon > redRoundsWon ? fight.blueFighterId : fight.redFighterId
                    let method = round.victoryDecision?.rawValue ?? "Points"
                    
                    let blueTotalScore = rounds.reduce(0) { $0 + $1.blueScore }
                    let redTotalScore = rounds.reduce(0) { $0 + $1.redScore }
                    
                    fight.fightResult = FightResult(
                        winner: winner,
                        method: method,
                        totalScore: (blue: blueTotalScore, red: redTotalScore)
                    )
                    
                    FirebaseService.shared.updateFight(fight) { result in
                        switch result {
                        case .success:
                            self?.showAlert(title: "Success", message: "Fight updated successfully")
                        case .failure(let error):
                            self?.showAlert(title: "Error", message: "Failed to update fight: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                print("Failed to get rounds: \(error.localizedDescription)")
            }
        }
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


    func resetTimer() {
        remainingTime = chronoDuration
        updateTimerLabel()
    }

    func resetScores() {
        blueScore = 0
        redScore = 0
        updateUI()
    }
   
    func calculateScore(for color: FighterColor) -> Int {
        let directPoints = currentRound?.actions.filter { $0.color == color && $0.actionType != .gamJeon && $0.isActive }.reduce(0) { $0 + $1.points } ?? 0
        let opponentColor: FighterColor = color == .blue ? .red : .blue
        let gamjeonPoints = currentRound?.actions.filter { $0.color == opponentColor && $0.actionType == .gamJeon && $0.isActive }.count ?? 0
        return directPoints + gamjeonPoints
    }

    func countGamjeons(for color: FighterColor) -> Int {
        return currentRound?.actions.filter { $0.color == color && $0.actionType == .gamJeon && $0.isActive }.count ?? 0
    }

   

   
    func handleRoundEnd() {
           timer?.invalidate()
           saveRoundData()
       }
    func saveRoundData() {
        guard let fight = fight else { return }
        
        guard let roundTime = currentRound?.roundTime else {
                   print("Error: Round time is not set")
                   return
               }
        
        let newRound = Round(
            fightId: fight.id ?? "",
            roundNumber: (fight.roundIds?.count ?? 0) + 1,
            chronoDuration: chronoDuration,
            duration: chronoDuration - remainingTime,
            roundTime: roundTime,
            blueFighterId: fight.blueFighterId,
            redFighterId: fight.redFighterId,
            actions: [], // Vous devrez implémenter la logique pour collecter les actions
            videoReplays: [], // Idem pour les replays vidéo
            isSynced: false
        )
        
        FirebaseService.shared.saveRound(newRound, for: fight) { [weak self] result in
            switch result {
            case .success:
                self?.showAlert(title: "Success", message: "Round saved successfully")
            case .failure(let error):
                self?.showAlert(title: "Error", message: "Failed to save round: \(error.localizedDescription)")
            }
        }
    }



    @IBAction func blueIvrTapped(_ sender: UIButton) {
        isIVRRequest = true // Définit IVR request à true pour une requête IVR

        handleVideoReplayRequest(for: .blue, sourceView: sender)
    }

    @IBAction func redIvrTapped(_ sender: UIButton) {
        isIVRRequest = true // Définit IVR request à true pour une requête IVR

        handleVideoReplayRequest(for: .red, sourceView: sender)
    }

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
                    self.updateUI()
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

        updateUI()
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
            updateUI()
            
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
     
        updateUI()
        resumeTimer()
    }}

extension AddRoundViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let mediaType = info[.mediaType] as? UTType, mediaType == .movie else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        // Récupérer l'URL de la vidéo sélectionnée
        if let videoURL = info[.mediaURL] as? URL {
            // Upload la vidéo sur Firebase
            uploadVideo(videoURL: videoURL)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func uploadVideo(videoURL: URL) {
        guard let fight = fight else { return }

        progressView.isHidden = false // Afficher la barre de progression

        FirebaseService.shared.uploadVideo(for: fight, videoURL: videoURL, progressHandler: { [weak self] progress in
            DispatchQueue.main.async {
                self?.progressView.setProgress(Float(progress), animated: true)
            }
        }) { [weak self] result in
            DispatchQueue.main.async {
                self?.progressView.isHidden = true // Masquer la barre de progression une fois l'upload terminé
            }

            switch result {
            case .success(let video):
                print("Video uploaded successfully: \(video.url)")
                if let videoURL = URL(string: video.url) {
                    self?.setupVideoPlayer(with: videoURL)
                    self?.setChronoDuration(video.duration)
                }
            case .failure(let error):
                print("Failed to upload video: \(error.localizedDescription)")
                self?.showAlert(title: "Upload Error", message: "Failed to upload video.")
            }
        }
    }


}
