//  AddRoundViewController+Timer.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import Foundation

extension AddRoundViewController {

    // MARK: - Timer Management

    /// Starts the round timer. If the timer is paused, it resumes with a time interval based on the remaining time.
    func startTimer() {
        guard isPaused else { return }
        isPaused = false
        playVideo()

        let interval: TimeInterval = remainingTime > 10 ? 1.0 : 0.01
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true)
        { [weak self] _ in
            self?.updateTimer()
        }
    }

    /// Updates the timer each second (or centisecond) based on the remaining time. Pauses the timer when time runs out.
    func updateTimer() {
        guard !isPaused else { return }

        if remainingTime > 0 {
            if remainingTime <= 10 {
                remainingTime -= 0.01  // Switch to centiseconds mode
            } else {
                remainingTime -= 1
            }
            updateTimerLabel()
        } else {
            pauseTimer()  // Pause when time reaches zero
            // Handle the end of the round here
        }
    }

    /// Updates the displayed timer label.
    /// Shows time in minutes:seconds format for times greater than 10 seconds, or in seconds:centiseconds format for times less than 10 seconds.
    func updateTimerLabel() {
        if remainingTime > 10 {
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        } else {
            let seconds = Int(remainingTime)
            let centiseconds = Int((remainingTime - Double(seconds)) * 100)
            timerLabel.text = String(format: "%02d:%02d", seconds, centiseconds)

            // Adjust the timer interval to a faster frequency
            if timer?.timeInterval != 0.01 {
                pauseTimer()
                startTimer()  // Restart the timer at a 0.01s interval
            }
        }
    }

    /// Pauses the round timer and invalidates it.
    /// Also pauses the video and updates the button to show "Resume."
    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        pauseVideo()
        pauseResumeButton.setTitle("Resume", for: .normal)
    }

    /// Resumes the round timer by restarting it.
    func resumeTimer() {
        startTimer()
    }

    /// Updates the remaining time to a new value and restarts the timer with the new interval.
    func updateRemainingTime(_ newTime: TimeInterval) {
        remainingTime = newTime
        updateTimerLabel()

        // Restart the timer with the updated time
        timer?.invalidate()
        startTimer()
    }

}
