//
//  AddRoundViewController+Gestures.swift
//  datafight
//
//  Created by younes ouasmi on 27/08/2024.
//

import UIKit

extension AddRoundViewController {

    func setupZoneGestures() {
        let zones = [gestureZ1, gestureZ2, gestureZ3]
        
        for (index, zone) in zones.enumerated() {
            guard let zone = zone else { continue }
            
            zone.tag = index
            zone.isUserInteractionEnabled = true
            
            // Triple Tap Gesture for head kicks
            let tripleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap(_:)))
            tripleTapGesture.numberOfTapsRequired = 3
            zone.addGestureRecognizer(tripleTapGesture)
            
            // Double Tap Gesture for Gamjeon
            let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTapGesture.require(toFail: tripleTapGesture)
            doubleTapGesture.numberOfTapsRequired = 2
            zone.addGestureRecognizer(doubleTapGesture)
            
            // Tap Gesture
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleZoneTap(_:)))
            tapGesture.require(toFail: tripleTapGesture)
            tapGesture.require(toFail: doubleTapGesture)
            zone.addGestureRecognizer(tapGesture)
            
            // Swipe Gestures
            let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
            for direction in directions {
                let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleZoneSwipe(_:)))
                swipeGesture.direction = direction
                zone.addGestureRecognizer(swipeGesture)
            }
        }
    }

    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view as? UIImageView else { return }
        
        print("Zone double tapped for Gamjeon: \(tappedView.tag)")
        showVisualFeedback(for: tappedView)
        
        let zoneIndex = tappedView.tag
        let zoneName = ["Z1", "Z2", "Z3"][zoneIndex]
        let zone = Zone(rawValue: zoneName)!
        let timeStamp = chronoDuration - remainingTime
        
        let action = Action(
            id: UUID().uuidString,
            fighterId: "", // Empty, will be set in ActionPickerView
            color: .blue, // Default, will be set in ActionPickerView
            actionType: .gamJeon,
            technique: nil,
            limbUsed: nil,
            actionZone: zone,
            timeStamp: chronoDuration - remainingTime,
            situation: nil,
            gamjeonType: nil,
            guardPosition: nil,
            videoTimestamp: timeStamp
        )
        
        pauseTimer()
        showActionDetailsInterface(for: action, points: -1,  isIVRRequest: false)
    }

    @objc func handleZoneTap(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view as? UIImageView else { return }
        
        print("Zone tapped: \(tappedView.tag)")
        showVisualFeedback(for: tappedView)
        
        let zoneIndex = tappedView.tag
        let zoneName = ["Z1", "Z2", "Z3"][zoneIndex]
        let zone = Zone(rawValue: zoneName)!
        let timeStamp = chronoDuration - remainingTime

        
        let action = Action(
            id: UUID().uuidString,
            fighterId: "", // Empty, will be set in ActionPickerView
            color: .blue, // Default, will be set in ActionPickerView
            actionType: .punch,
            technique: .punch,
            limbUsed: nil,
            actionZone: zone,
            timeStamp: chronoDuration - remainingTime,
            situation: .attack,
            gamjeonType: nil,
            guardPosition: nil,
            videoTimestamp: timeStamp

            
        )
        
        pauseTimer()
        showActionDetailsInterface(for: action, points: 1,  isIVRRequest: false)
    }

    @objc func handleZoneSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let swipedView = gesture.view as? UIImageView else { return }
        
        print("Zone swiped: \(swipedView.tag), Direction: \(gesture.direction)")
        showVisualFeedback(for: swipedView)
        
        let zoneIndex = swipedView.tag
        let zoneName = ["Z1", "Z2", "Z3"][zoneIndex]
        let zone = Zone(rawValue: zoneName)!
        let timeStamp = chronoDuration - remainingTime

        
        var situation: CombatSituation
        switch gesture.direction {
        case .right: situation = .attack
        case .down: situation = .clinch
        case .left: situation = .defense
        case .up: situation = .attack
        default: return
        }
        
        let action = Action(
            id: UUID().uuidString,
            fighterId: "", // Empty, will be set in ActionPickerView
            color: .blue, // Default, will be set in ActionPickerView
            actionType: .kick,
            technique: nil,
            limbUsed: nil,
            actionZone: zone,
            timeStamp: chronoDuration - remainingTime,
            situation: situation,
            gamjeonType: nil,
            guardPosition: nil,
            videoTimestamp: timeStamp

        )
        
        pauseTimer()
        showActionDetailsInterface(for: action, points: 2,  isIVRRequest: false)
    }

    @objc func handleTripleTap(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view as? UIImageView else { return }
        
        print("Triple tap on zone: \(tappedView.tag)")
        showVisualFeedback(for: tappedView)
        
        let zoneIndex = tappedView.tag
        let zoneName = ["Z1", "Z2", "Z3"][zoneIndex]
        let zone = Zone(rawValue: zoneName)!
        let timeStamp = chronoDuration - remainingTime

        
        let action = Action(
            id: UUID().uuidString,
            fighterId: "", // Empty, will be set in ActionPickerView
            color: .blue, // Default, will be set in ActionPickerView
            actionType: .kick,
            technique: nil,
            limbUsed: nil,
            actionZone: zone,
            timeStamp: chronoDuration - remainingTime,
            situation: .attack,
            gamjeonType: nil,
            guardPosition: nil,
            videoTimestamp: timeStamp

        )
        
        pauseTimer()
        showActionDetailsInterface(for: action, points: 3,  isIVRRequest: false)
    }
    
    private func showVisualFeedback(for view: UIView) {
        UIView.animate(withDuration: 0.2, animations: {
            view.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                view.alpha = 1.0
            }
        }
    }

}

