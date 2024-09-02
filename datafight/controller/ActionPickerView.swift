//
//  ActionPickerView.swift
//  datafight
//
//  Created by younes ouasmi on 26/08/2024.
//

import UIKit

class ActionPickerView: UIView {
    private var titleLabel: UILabel!
    private var stackView: UIStackView!
    private var action: Action
    private var points: Int
    private var onActionComplete: ((Action?) -> Void)?
    private var onCancel: (() -> Void)?
    private var onUndo: (() -> Void)?
    private var isSpinningKick: Bool?
    private var currentCategory: ActionCategory
    private var isIVRRequest: Bool // Indique si c'est une IVR Request

    
    private var previousSelections: [(category: ActionCategory, action: Action)] = []
    
    enum ActionCategory {
        case selectFighter
        case spinningKickQuestion
        case technique
        case limb
        case guardPosition
        case gamjeonType
        case situation
        case actionType // Nouveau cas pour déterminer le type d'action
        case impactArea // Nouveau cas pour déterminer la zone d'impact
        case zone
    }
    
    init(frame: CGRect, initialAction: Action, points: Int, isIVRRequest: Bool, onComplete: @escaping (Action?) -> Void, onCancel: @escaping () -> Void, onUndo: @escaping () -> Void) {
        self.action = initialAction
        self.points = points
        self.isIVRRequest = isIVRRequest // Initialisation de la nouvelle propriété
        self.onActionComplete = onComplete
        self.onCancel = onCancel
        self.onUndo = onUndo
        self.currentCategory = isIVRRequest ? .zone : .selectFighter

        
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        
        titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        cancelButton.backgroundColor = .systemRed
        cancelButton.layer.cornerRadius = 10
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        addSubview(cancelButton)
        
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("Undo", for: .normal)
        undoButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        undoButton.backgroundColor = .systemYellow
        undoButton.layer.cornerRadius = 10
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        addSubview(undoButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            
            undoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            undoButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            undoButton.widthAnchor.constraint(equalToConstant: 100),
            undoButton.heightAnchor.constraint(equalToConstant: 50),
            
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: cancelButton.topAnchor, constant: -20)
        ])
        
        updateForCurrentCategory()
    }
    
    @objc private func cancelButtonTapped() {
        onCancel?()
    }
    
    @objc private func undoButtonTapped() {
        if let lastSelection = previousSelections.popLast() {
            currentCategory = lastSelection.category
            action = lastSelection.action
            updateForCurrentCategory()
        } else {
            onUndo?()
        }
    }
    
    private func addButtons(options: [String], actionHandler: @escaping (Int) -> Void) {
        for (index, option) in options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            button.layer.cornerRadius = 10
            button.backgroundColor = .systemGray6
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        self.buttonActionHandler = actionHandler
    }
    
    private var buttonActionHandler: ((Int) -> Void)?
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let index = sender.tag
        previousSelections.append((category: currentCategory, action: action))
        buttonActionHandler?(index)
    }
    
    private func moveToNextCategory() {
        print("Moving from category: \(currentCategory)")

        if isIVRRequest  {
            // Logique simplifiée pour IVR Request
            switch currentCategory {
            case .zone:
                currentCategory = .actionType
            case .actionType:
                if action.actionType == .kick {
                    currentCategory = .impactArea
                } else if action.actionType == .punch {
                    currentCategory = .limb
                } else if action.actionType == .gamJeon {
                    currentCategory = .gamjeonType
                }else{
                    currentCategory = .technique
                }

            case .impactArea:
                currentCategory = .spinningKickQuestion

            case .spinningKickQuestion:
                currentCategory = .technique

            case .technique:
                currentCategory = .limb

            case .limb:
                currentCategory = .guardPosition

            case .guardPosition:
                currentCategory = .situation
                
            case .gamjeonType:
                currentCategory = .situation
                

            case .situation:
                onActionComplete?(action)
                return

            default:
                break
            }
        } else {
            // Logique existante
            switch currentCategory {
            case .selectFighter:
                if action.actionType == .gamJeon {
                    currentCategory = .gamjeonType
                } else if action.actionType == .kick {
                    currentCategory = .spinningKickQuestion
                } else if action.actionType == .punch || points == 1 {
                    currentCategory = .limb
                } else {
                    currentCategory = .technique
                }

            case .spinningKickQuestion:
                currentCategory = .technique

            case .technique:
                currentCategory = .limb

            case .limb:
                currentCategory = .guardPosition

            case .guardPosition:
                if !(action.actionType == .kick && (points == 2 || points == 4)) {
                    currentCategory = .situation
                } else {
                    onActionComplete?(action)
                    return
                }

            case .gamjeonType:
                currentCategory = .situation

            case .situation:
                onActionComplete?(action)
                return
            default:
                print("Unhandled category: \(currentCategory)")
            }
        }

        updateForCurrentCategory()
    }

    
    private func updateForCurrentCategory() {
        print("Updating UI for category: \(currentCategory)")
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        switch currentCategory {
            
        case .zone:
            titleLabel.text = "Select action Zone "
            addButtons(options: Zone.allCases.map { $0.rawValue }) { [weak self] selectedIndex in
                self?.action.actionZone = Zone.allCases[selectedIndex]
                self?.moveToNextCategory()
            }
        case .actionType:
            titleLabel.text = "Select action Type "
            addButtons(options: ActionType.allCases.map { $0.rawValue }) { [weak self] selectedIndex in
                self?.action.actionType = ActionType.allCases[selectedIndex]
                self?.moveToNextCategory()
            }
            
        
        case .impactArea:
            titleLabel.text = "Select Impact Area"
            addButtons(options: ["Head (3 points)", "Chest (2 points)"]) { [weak self] selectedIndex in
                self?.points = selectedIndex == 0 ? 3 : 2
                self?.moveToNextCategory()
            }
        case .selectFighter:
            titleLabel.text = "Who did the action?"
            addButtons(options: ["Blue Fighter", "Red Fighter"]) { [weak self] selectedIndex in
                self?.action.color = selectedIndex == 0 ? .blue : .red
                self?.action.fighterId = selectedIndex == 0 ? self?.action.blueFighterId ?? "" : self?.action.redFighterId ?? ""
                self?.moveToNextCategory()
            }
            
        case .spinningKickQuestion:
            titleLabel.text = "Spinning Kick?"
            addButtons(options: ["Yes", "No"]) { [weak self] selectedIndex in
                self?.isSpinningKick = selectedIndex == 0
                if self?.isSpinningKick == true {
                    self?.points = (self?.points == 2 ? 4 : (self?.points == 3 ? 5 : self?.points)) ?? self?.points ?? 0
                }
                self?.moveToNextCategory()
            }
            
        case .technique:
            titleLabel.text = "Select Technique"
            let techniques = Technique.allCases.filter { $0.points == self.points }
            addButtons(options: techniques.map { $0.rawValue }) { [weak self] selectedIndex in
                self?.action.technique = techniques[selectedIndex]
                self?.moveToNextCategory()
            }
            
        case .limb:
            titleLabel.text = "Select Limb"
            let limbs = action.actionType == .kick ?
                Limb.allCases.filter { $0.rawValue.contains("Leg") } :
                Limb.allCases.filter { $0.rawValue.contains("Arm") }
            addButtons(options: limbs.map { $0.rawValue }) { [weak self] selectedIndex in
                self?.action.limbUsed = limbs[selectedIndex]
                self?.moveToNextCategory()
            }
            
        case .guardPosition:
            titleLabel.text = "Guard Position"
            addButtons(options: GuardPosition.allCases.map { $0.rawValue }) { [weak self] selectedIndex in
                self?.action.guardPosition = GuardPosition.allCases[selectedIndex]
                self?.moveToNextCategory()
            }
            
        case .gamjeonType:
            titleLabel.text = "Gamjeon Type"
            addButtons(options: GamjeonType.allCases.map { $0.rawValue }) { [weak self] selectedIndex in
                self?.action.gamjeonType = GamjeonType.allCases[selectedIndex]
                self?.moveToNextCategory()
            }
            
        case .situation:
            titleLabel.text = "Select Situation"
            addButtons(options: CombatSituation.allCases.map { $0.rawValue }) { [weak self] selectedIndex in
                self?.action.situation = CombatSituation.allCases[selectedIndex]
                self?.moveToNextCategory()
            }
        }
    }
}
