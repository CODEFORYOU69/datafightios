//
//  AddRoundViewController+Video.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import AVFoundation
import AVKit

extension AddRoundViewController {
    
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
                // Charger la durée de la vidéo
                let duration = try await asset.load(.duration)
                let durationInSeconds = CMTimeGetSeconds(duration)
                
                // Mettre à jour l'interface utilisateur sur le thread principal
                DispatchQueue.main.async { [weak self] in
                    self?.setChronoDuration(durationInSeconds)
                    self?.startTimerAndVideo() // Démarrer le chrono et la vidéo simultanément
                }
            } catch {
                print("Failed to load video duration: \(error.localizedDescription)")
            }
        }
    }

    func startTimerAndVideo() {
        // Démarrer le timer
        startTimer()

        // Démarrer la vidéo
        playVideo()
        updateVideoProgress()

    }
    func updateVideoProgress() {
        guard let player = videoPlayerView.player else { return }

        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let duration = player.currentItem?.duration.seconds ?? 0
            let currentTime = player.currentTime().seconds

            if duration > 0 {
                self.videoProgressView.progress = Float(currentTime / duration)
            }
        }
    }
    func playVideo() {
        videoPlayerView.player?.play()
    }

    func pauseVideo() {
        videoPlayerView.player?.pause()
    }

    func seekVideo(to time: CMTime) {
        videoPlayerView.player?.seek(to: time)
    }


}
extension AddRoundViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let videoURL = urls.first {
            uploadVideo(videoURL: videoURL)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    func promptForVideoUpload() {
        print("Prompting for video upload.")
        
        let alertController = UIAlertController(title: "Upload Video", message: "Please select the source to upload the video.", preferredStyle: .alert)
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            print("Photo Library selected.")
            self?.presentVideoPicker()
        }
        
        let filePickerAction = UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            print("Files selected.")
            self?.presentDocumentPicker()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Video upload canceled.")
        }
        
        alertController.addAction(photoLibraryAction)
        alertController.addAction(filePickerAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = self.view.bounds
            popoverController.permittedArrowDirections = [.down, .up]
        }
        
        present(alertController, animated: true) {
            print("Upload video alert presented.")
        }
    }


}
