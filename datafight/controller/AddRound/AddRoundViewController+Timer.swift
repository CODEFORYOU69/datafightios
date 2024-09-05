//
//  AddRoundViewController+Timer.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import Foundation

extension AddRoundViewController {
    
    
    
    func startTimer() {
        guard isPaused else { return }
        isPaused = false
        playVideo()

        let interval: TimeInterval = remainingTime > 10 ? 1.0 : 0.01
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    func updateTimer() {
        guard !isPaused else { return }

        if remainingTime > 0 {
            if remainingTime <= 10 {
                // Basculer en mode centièmes de secondes
                remainingTime -= 0.01
            } else {
                remainingTime -= 1
            }
            updateTimerLabel()
        } else {
            pauseTimer()
            // Gérer la fin du round ici
        }
    }

    func updateTimerLabel() {
        if remainingTime > 10 {
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        } else {
            let seconds = Int(remainingTime)
            let centiseconds = Int((remainingTime - Double(seconds)) * 100)
            timerLabel.text = String(format: "%02d:%02d", seconds, centiseconds)
            
            // Ajuster l'intervalle du timer pour passer à une fréquence plus rapide
            if timer?.timeInterval != 0.01 {
                pauseTimer()
                startTimer()  // Recommencer le timer à 0,01s d'intervalle
            }
        }
    }

    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        pauseVideo()
        pauseResumeButton.setTitle("Resume", for: .normal)
    }

    func resumeTimer() {
        startTimer()
    }
    func updateRemainingTime(_ newTime: TimeInterval) {
        remainingTime = newTime
        updateTimerLabel()
        
        // Redémarrer le timer avec le nouveau temps
        timer?.invalidate()
        startTimer()
    }


}
