//
//  AddRoundViewController+Video.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import AVFoundation
import AVKit

extension AddRoundViewController {

    // MARK: - Video Upload

    /// Uploads a video to Firebase and sets up the video player
    func uploadVideo(videoURL: URL) {
        guard let fight = fight else {
            print("Error: No fight object available")
            return
        }

        print("Starting video upload process")
        FirebaseService.shared.uploadVideo(
            for: fight, videoURL: videoURL,
            progressHandler: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progressView.setProgress(
                        Float(progress), animated: true)
                }
            }
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.progressView.isHidden = true

                switch result {
                case .success(let video):
                    print("Video uploaded successfully: \(video.url)")
                    if let videoURL = URL(string: video.url) {
                        self?.setupVideoPlayer(with: videoURL)
                        self?.setChronoDuration(video.duration)
                    }
                case .failure(let error):
                    print(
                        "Failed to upload video: \(error.localizedDescription)")
                    self?.showAlert(
                        title: "Upload Error",
                        message:
                            "Failed to upload video: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Timer and Score Management

    /// Resets the timer to its initial state
    func resetTimer() {
        remainingTime = chronoDuration
        updateTimerLabel()
    }

    /// Resets the scores for both fighters
    func resetScores() {
        blueScore = 0
        redScore = 0
        manageScores()
    }

    // MARK: - Video Navigation

    /// Skips the video forward or backward by a specified number of seconds
    func skipTime(by seconds: Double) {
        guard let player = videoPlayerView.player else { return }
        let currentTime = player.currentTime().seconds
        let newTime = max(0, currentTime + seconds)

        seekVideo(
            to: CMTime(
                seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        )
        remainingTime = chronoDuration - newTime
        updateTimerLabel()
    }

    /// Handles taps on the video progress bar
    @objc func handleProgressTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: videoProgressView)
        let percentage = Float(location.x / videoProgressView.bounds.width)
        let duration =
            videoPlayerView.player?.currentItem?.duration.seconds ?? 0
        let newTime = duration * Double(percentage)

        seekVideo(
            to: CMTime(
                seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        )
        updateChronoTime(fromVideoTime: newTime)
    }

    // MARK: - Video Playback Control

    /// Starts both the timer and the video playback
    func startTimerAndVideo() {
        playVideo()
        startTimer()
        updateVideoProgress()
    }

    /// Updates the video progress bar
    func updateVideoProgress() {
        guard let player = videoPlayerView.player else { return }

        let interval = CMTime(
            seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            [weak self] time in
            guard let self = self else { return }
            let duration = player.currentItem?.duration.seconds ?? 0
            let currentTime = player.currentTime().seconds

            if duration > 0 {
                self.videoProgressView.progress = Float(currentTime / duration)
                self.updateChronoTime(fromVideoTime: currentTime)
            }
        }
    }

    /// Updates the chrono time based on the current video time
    func updateChronoTime(fromVideoTime videoTime: TimeInterval) {
        let elapsedTimeInRound = videoTime - currentRoundStartTime
        remainingTime = max(0, chronoDuration - elapsedTimeInRound)
        updateTimerLabel()
    }

    /// Plays the video
    func playVideo() {
        videoPlayerView.player?.play()
    }

    /// Pauses the video
    func pauseVideo() {
        videoPlayerView.player?.pause()
    }

    /// Seeks the video to a specific time
    func seekVideo(to time: CMTime) {
        videoPlayerView.player?.seek(to: time)
    }
}

// MARK: - UIDocumentPickerDelegate

extension AddRoundViewController: UIDocumentPickerDelegate {
    /// Handles the selection of a document (video) from the document picker
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        if let videoURL = urls.first {
            uploadVideo(videoURL: videoURL)
        }
    }

    /// Handles the cancellation of the document picker
    func documentPickerWasCancelled(
        _ controller: UIDocumentPickerViewController
    ) {
        dismiss(animated: true, completion: nil)
    }

    /// Prompts the user to choose a source for video upload
    func promptForVideoUpload() {
        print("Prompting for video upload.")

        let alertController = UIAlertController(
            title: "Upload Video",
            message: "Please select the source to upload the video.",
            preferredStyle: .alert)

        let photoLibraryAction = UIAlertAction(
            title: "Photo Library", style: .default
        ) { [weak self] _ in
            print("Photo Library selected.")
            self?.presentVideoPicker()
        }

        let filePickerAction = UIAlertAction(title: "Files", style: .default) {
            [weak self] _ in
            print("Files selected.")
            self?.presentDocumentPicker()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Video upload canceled.")
        }

        alertController.addAction(photoLibraryAction)
        alertController.addAction(filePickerAction)
        alertController.addAction(cancelAction)

        if let popoverController = alertController.popoverPresentationController
        {
            popoverController.sourceView = self.view  // Ensure the source is set
            popoverController.sourceRect = CGRect(
                x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0,
                height: 0)
            popoverController.permittedArrowDirections = []
        }

        presentAlert(alertController)
    }
}
