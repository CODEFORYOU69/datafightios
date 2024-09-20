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



class AddRoundViewController: UIViewController, RoundWinnerDeterminer {
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
    
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
        undoLastAction()
    }
    
    @IBAction func setTimeButtonTapped(_ sender: UIButton) {
        showSetTimeModal()
    }
    
    @IBAction func pauseResumeButtonTapped(_ sender: UIButton) {
        if isPaused {
            resumeTimer()
        } else {
            pauseTimer()
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
    var progressView: UIProgressView!
    var currentRoundStartTime: TimeInterval = 0
    let MAX_ROUNDS = 3
    var redRoundWon: Int = 0
    var blueRoundWon: Int = 0
    var actionPicker: ActionPickerView?
    var videoPlayerView: VideoPlayerView!
    var videoTimer: Timer?
    var rounds: [Round] = []

    
    
    var isAlertPresented = false

    func presentAlert(_ alertController: UIAlertController) {
           guard !isAlertPresented else {
               print("An alert is already presented, skipping this one.")
               return
           }
           
           isAlertPresented = true
           present(alertController, animated: true) {
               self.isAlertPresented = false
           }
       }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupVideoPlayer()

        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseVideo()
        
    }
    
    func updateRoundNumberLabel() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.roundNumberLabel.text = "\(self.currentRoundNumber)"
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupVideoPlayer()
        requestRoundTime()
        setupZoneGestures()
        setupProgressView()
        setCurrentRoundNumber()
        updateRoundNumberLabel()
        manageScores()
        print("Fight: \(String(describing: fight))")

    }
    
    
    func initializeRound(with roundTime: Int, completion: @escaping () -> Void) {
        print("Fight data: \(String(describing: fight))")

        guard let fight = fight else {
            print("Error: No fight found")
            completion()
            return
        }
        
        let nextRoundNumber = (fight.roundIds?.count ?? 0) + 1
        
        FirebaseService.shared.getLastRoundEndTime(for: fight) { [weak self] result in
            guard let self = self else { return }
            
            let lastEndTime: TimeInterval
            switch result {
            case .success(let time):
                lastEndTime = time
            case .failure(let error):
                print("Failed to get last round end time: \(error.localizedDescription)")
                lastEndTime = 0
            }
            
            self.requestNewRoundStartTime(lastEndTime: lastEndTime) { newStartTime in
                self.currentRound = Round(
                    id: nil,
                    fightId: fight.id ?? "",
                    roundNumber: nextRoundNumber,
                    chronoDuration: 0,
                    duration: 0,
                    roundTime: roundTime,
                    blueFighterId: fight.blueFighterId,
                    redFighterId: fight.redFighterId,
                    actions: [],
                    videoReplays: [],
                    isSynced: false,
                    victoryDecision: nil,
                    roundWinner: nil,
                    startTime: newStartTime
                )
                print("video id initail: \(String(describing: fight.videoId))")
                self.checkForVideo()
                
                if fight.videoId != nil {
                    self.updateVideoRoundTimestamps(roundNumber: nextRoundNumber, startTime: newStartTime)
                }
                

                completion()
            }
        }
    }
    func requestNewRoundStartTime(lastEndTime: TimeInterval, completion: @escaping (TimeInterval) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let alertController = UIAlertController(
                title: "New Round Start Time",
                message: "Enter the start time for the new round (in seconds):\nLast round ended at: \(lastEndTime) seconds",
                preferredStyle: .alert
            )

            alertController.addTextField { textField in
                textField.placeholder = "Start Time (seconds)"
                textField.keyboardType = .decimalPad
                textField.text = String(lastEndTime)
            }

            let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
                let newStartTime = TimeInterval(alertController.textFields?.first?.text ?? "") ?? lastEndTime
                completion(newStartTime)
            }

            alertController.addAction(confirmAction)

            // Présenter le UIAlertController uniquement si la vue est visible
            if self.isViewLoaded && self.view.window != nil {
                self.present(alertController, animated: true, completion: nil)
            } else {
                print("Warning: Tried to present alert but the view was not in hierarchy")
            }
        }
    }


    func checkForVideo() {
        guard let fight = fight else {
            print("Error: No fight found")
            return
        }

        if let videoURLString = fight.videoURL, !videoURLString.isEmpty, let videoURL = URL(string: videoURLString) {
            print("Video found, setting up video player.")
            setupVideoPlayer(with: videoURL)
        } else {
            print("No video found, prompting for video upload.")
            DispatchQueue.main.async { [weak self] in
                self?.promptForVideoUpload()
            }
        }
    }

    func setupVideoPlayer(with url: URL) {
        guard videoPlayerView != nil else {
            print("Error: setup videoPlayerView is nil")
            return
        }

        print("Video found, setting up video player.")
        videoPlayerView.loadVideo(url: url)
        
        let asset = AVAsset(url: url)
        
        Task {
            do {
                let duration = try await asset.load(.duration)
                let durationInSeconds = CMTimeGetSeconds(duration)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.setChronoDuration(durationInSeconds)
                    
                    // Positionner la vidéo au début du round actuel
                    if let startTime = self.currentRound?.startTime {
                        self.seekVideo(to: CMTime(seconds: startTime, preferredTimescale: 600))
                    }
                    
                    self.startTimerAndVideo()
                }
            } catch {
                print("Failed to load video duration: \(error.localizedDescription)")
            }
        }
    }

    func updateVideoRoundTimestamps(roundNumber: Int, startTime: TimeInterval) {
        print("Updating round video timestamps for round \(roundNumber) with start time \(startTime)")

        guard let fight = fight else {
               print("Error: Missing fight or video ID")
               return
           }
        FirebaseService.shared.updateVideoRoundTimestamps(for: fight, roundNumber: roundNumber, startTime: startTime) { result in
            switch result {
            case .success:
                print("Video round timestamps updated successfully")
            case .failure(let error):
                print("Failed to update video round timestamps: \(error.localizedDescription)")
            }
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
    
    func requestRoundTime() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let alertController = UIAlertController(title: "Round Duration", message: "Enter the duration of the round (in minutes):", preferredStyle: .alert)

            alertController.addTextField { textField in
                textField.placeholder = "Minutes"
                textField.keyboardType = .numberPad
            }

            let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
                if let minutesString = alertController.textFields?.first?.text,
                   let minutes = Int(minutesString) {
                    // Convertir les minutes en secondes pour roundTime
                    let roundTimeInSeconds = minutes * 60
                    self.initializeRound(with: roundTimeInSeconds) {
                       
                    }
                } else {
                    // Si aucune valeur n'est entrée, répéter la demande
                    self.requestRoundTime()
                }
            }

            alertController.addAction(confirmAction)

            // Vérifier que la vue est visible avant de présenter l'alerte
            if self.isViewLoaded && self.view.window != nil {
                self.present(alertController, animated: true, completion: nil)
            } else {
                print("Warning: Tried to present alert but the view was not in hierarchy")
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
            currentRoundStartTime = 0
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
                    self.currentRoundStartTime = lastRoundEndTime
                    self.chronoDuration = duration - lastRoundEndTime
                    self.remainingTime = self.chronoDuration
                    
                    print("Last round found:")
                    print("  Round Number: \(lastRoundTimestamp.roundNumber)")
                    print("  Round End Time: \(lastRoundEndTime)")
                    print("Set chronoDuration to \(self.chronoDuration) and remainingTime to \(self.remainingTime)")
                    print("Current round number f set to: \(self.currentRoundNumber)")
                } else {
                    print("No previous rounds, starting from the beginning of the video")
                    self.currentRoundStartTime = 0
                    self.chronoDuration = duration
                    self.remainingTime = duration
                    self.currentRoundNumber = 1
                    print("Set chronoDuration and remainingTime to \(duration)")
                    print("Current round number h set to: \(self.currentRoundNumber)")
                }
                
                DispatchQueue.main.async {
                    self.updateRoundNumberLabel()
                    self.seekVideo(to: CMTime(seconds: self.currentRoundStartTime, preferredTimescale: 600))
                    self.updateChronoTime(fromVideoTime: self.currentRoundStartTime)
                }
                
            case .failure(let error):
                print("Failed to fetch video: \(error.localizedDescription)")
                self.currentRoundStartTime = 0
                self.chronoDuration = duration
                self.remainingTime = duration
                self.currentRoundNumber = 1
                print("Due to error, set both chronoDuration and remainingTime to \(duration)")
                print("Current round number set y to: \(self.currentRoundNumber)")
                
                DispatchQueue.main.async {
                    self.updateRoundNumberLabel()
                    self.updateChronoTime(fromVideoTime: 0)
                }
            }
        }
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
            onUndo: {
                // Ajoutez ici une action à effectuer en cas d'annulation, même si c'est juste un log
                print("Undo action triggered")
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
}

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
    
    
    
    
}
