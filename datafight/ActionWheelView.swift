//
//  ActionWheelView.swift
//  datafight
//
//  Created by younes ouasmi on 24/08/2024.
//

import UIKit

class ActionWheelView: UIView {
    private var segments: [UIButton] = []
    private var currentCategory: ActionCategory
    private var action: Action
    private var points: Int
    private var onActionComplete: ((Action?) -> Void)?
    private var cancelButton: UIButton!
    private var titleLabel: UILabel!
    private var isSpinningKick: Bool?
    
    enum ActionCategory {
        case technique
        case limb
        case guardPosition
        case gamjeonType
        case situation
        case spinningKickQuestion
    }
    
    init(frame: CGRect, initialAction: Action, points: Int, onComplete: @escaping (Action?) -> Void) {
        self.action = initialAction
        self.points = points
        self.onActionComplete = onComplete
        
        if initialAction.actionType == .gamJeon {
            self.currentCategory = .gamjeonType
        } else if initialAction.actionType == .kick {
            self.currentCategory = .spinningKickQuestion
        } else {
            self.currentCategory = .technique
        }
        
        super.init(frame: frame)
        setupWheel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWheel() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        layer.cornerRadius = frame.width / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.3
        
        setupTitleLabel()
        setupSegments()
        setupCancelButton()
        updateSegments()
    }
    
    private func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 20)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    private func setupSegments() {
        let segmentCount = 6
        let angleSize = 2 * CGFloat.pi / CGFloat(segmentCount)
        let radius = frame.width / 2 - 70
        
        for i in 0..<segmentCount {
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 0, y: 0, width: 120, height: 60)
            let angle = angleSize * CGFloat(i) - CGFloat.pi / 2
            let buttonCenter = CGPoint(
                x: cos(angle) * radius + bounds.midX,
                y: sin(angle) * radius + bounds.midY
            )
            button.center = buttonCenter
            button.backgroundColor = UIColor(named: "AccentColor")?.withAlphaComponent(0.7)
            button.layer.cornerRadius = 15
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 5)
            button.layer.shadowRadius = 5
            button.layer.shadowOpacity = 0.2
            button.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 16)
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
            addSubview(button)
            segments.append(button)
        }
    }
    
    private func setupCancelButton() {
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.backgroundColor = UIColor(white: 0.9, alpha: 0.9)
        cancelButton.layer.cornerRadius = 20
        cancelButton.layer.shadowColor = UIColor.black.cgColor
        cancelButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        cancelButton.layer.shadowRadius = 5
        cancelButton.layer.shadowOpacity = 0.3
        cancelButton.frame = CGRect(x: 0, y: 0, width: 120, height: 50)
        cancelButton.center = CGPoint(x: bounds.midX, y: bounds.midY + frame.height / 4)
        cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        addSubview(cancelButton)
    }
    
    @objc private func cancelAction() {
        onActionComplete?(nil)
    }
    
    private func updateSegments() {
        let options: [String]
        
        switch currentCategory {
        case .spinningKickQuestion:
            titleLabel.text = "Spinning Kick?"
            options = ["Yes", "No"]
        case .technique:
            titleLabel.text = "Select Technique"
            options = Technique.allCases
                .filter { $0.points == self.points }
                .map { $0.rawValue }
        case .limb:
            titleLabel.text = "Select Limb"
            options = action.actionType == .kick ?
                Limb.allCases.filter { $0.rawValue.contains("Leg") }.map { $0.rawValue } :
                Limb.allCases.filter { $0.rawValue.contains("Arm") }.map { $0.rawValue }
        case .guardPosition:
            titleLabel.text = "Guard Position"
            options = GuardPosition.allCases.map { $0.rawValue }
        case .gamjeonType:
            titleLabel.text = "Gamjeon Type"
            options = GamjeonType.allCases.map { $0.rawValue }
        case .situation:
            titleLabel.text = "Select Situation"
            options = CombatSituation.allCases.map { $0.rawValue }
        }
        
        for (index, button) in segments.enumerated() {
            button.setTitle(options[safe: index], for: .normal)
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = button.bounds
            gradientLayer.colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            gradientLayer.cornerRadius = button.layer.cornerRadius
            button.layer.insertSublayer(gradientLayer, at: 0)
        }
    }
    
    @objc private func segmentTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        
        print("Button tapped: \(title) in category: \(currentCategory)")
        
        switch currentCategory {
        case .spinningKickQuestion:
            isSpinningKick = (title == "Yes")
            print("Is spinning kick: \(isSpinningKick ?? false)")
            if isSpinningKick == true {
                let oldPoints = points
                points = points == 2 ? 4 : (points == 3 ? 5 : points)
                print("Points updated from \(oldPoints) to \(points)")
            }
        case .technique:
            action.technique = Technique(rawValue: title)
            print("Selected technique: \(String(describing: action.technique))")
        case .limb:
            action.limbUsed = Limb(rawValue: title)
            print("Selected limb: \(String(describing: action.limbUsed))")
        case .guardPosition:
            action.guardPosition = GuardPosition(rawValue: title)
            print("Selected guard position: \(String(describing: action.guardPosition))")
        case .gamjeonType:
            action.gamjeonType = GamjeonType(rawValue: title)
            print("Selected gamjeon type: \(String(describing: action.gamjeonType))")
        case .situation:
            action.situation = CombatSituation(rawValue: title) ?? .attack
            print("Selected situation: \(String(describing: action.situation))")
        }
        
        moveToNextCategory()
    }

    private func moveToNextCategory() {
        let oldCategory = currentCategory
        
        switch currentCategory {
        case .spinningKickQuestion:
            currentCategory = .technique
        case .technique:
            currentCategory = .limb
        case .limb:
            currentCategory = .guardPosition
        case .guardPosition:
            if points == 3 || points == 5 {
                currentCategory = .situation
            } else {
                onActionComplete?(action)
                return
            }
        case .gamjeonType:
            currentCategory = .situation
        case .situation:
            print("Action completed with points: \(points)")
            onActionComplete?(action)
            return
        }
        
        print("Moving from \(oldCategory) to \(currentCategory)")
        updateSegments()
    }
}

