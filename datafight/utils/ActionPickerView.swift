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
    private let round: Round
    private var chronoLabel: UILabel?

    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    private func requestChronoTime() {
        titleLabel.text = "Select Remaining Time in Round"
        
        // Créer un UISlider
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = Float(round.roundTime)
        slider.value = Float(round.roundTime) / 2
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        // Créer un label pour afficher le temps sélectionné
        let timeLabel = UILabel()
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        timeLabel.text = formatTime(TimeInterval(slider.value))
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Ajouter un gestionnaire d'événements pour le slider
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        // Ajouter les vues au stackView
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(slider)
        
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmChronoTime), for: .touchUpInside)
        stackView.addArrangedSubview(confirmButton)
        
        self.chronoLabel = timeLabel
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        let selectedTime = TimeInterval(sender.value)
        chronoLabel?.text = formatTime(selectedTime)
    }

    @objc private func confirmChronoTime() {
        guard let timeString = chronoLabel?.text, !timeString.isEmpty else {
            print("Invalid time")
            return
        }
        
        let components = timeString.split(separator: ":")
        if components.count == 2, let minutes = Double(components[0]), let seconds = Double(components[1]) {
            let totalSeconds = (minutes * 60) + seconds
            action.chronoTimestamp = totalSeconds
            print("Chrono enregistré: \(totalSeconds) secondes")
            onActionComplete?(action)  // Action complète avec chrono
        } else {
            print("Format de temps incorrect")
        }
    }

    private var previousSelections: [(category: ActionCategory, action: Action)] = []
    
    enum ActionCategory {
        case selectFighter
        case spinningKickQuestion
        case technique
        case limb
        case guardPosition
        case gamjeonType
        case situation
        case chronoTimestamp
        case actionType // Nouveau cas pour déterminer le type d'action
        case impactArea // Nouveau cas pour déterminer la zone d'impact
        case zone
    }
    
    init(frame: CGRect, initialAction: Action, points: Int, isIVRRequest: Bool, round: Round, onComplete: @escaping (Action?) -> Void, onCancel: @escaping () -> Void, onUndo: @escaping () -> Void) {
        self.action = initialAction
        self.points = points
        self.isIVRRequest = isIVRRequest
        self.round = round // Ajouter cette ligne
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
        // Configuration du fond
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        layer.cornerRadius = 20
        layer.masksToBounds = false
        
        // Ajout d'ombre
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.3
        
        // Ajout d'une bordure
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor

        // Configuration du titre
        titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Configuration du stackView
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        // Configuration des boutons
        let cancelButton = createButton(title: "Cancel", color: .systemRed)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)

        let undoButton = createButton(title: "Undo", color: .systemYellow)
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)

        // Ajout des contraintes
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),

            undoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            undoButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
            undoButton.widthAnchor.constraint(equalToConstant: 120),
            undoButton.heightAnchor.constraint(equalToConstant: 50),

            stackView.bottomAnchor.constraint(lessThanOrEqualTo: cancelButton.topAnchor, constant: -30)
        ])

        updateForCurrentCategory()
    }

    private func createButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        return button
    }

    private func addButtons(options: [String], actionHandler: @escaping (Int) -> Void) {
        for (index, option) in options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.layer.cornerRadius = 15
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            
            // Ajout d'ombre au bouton
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 3)
            button.layer.shadowRadius = 5
            button.layer.shadowOpacity = 0.1
            button.layer.masksToBounds = false
            
            stackView.addArrangedSubview(button)
        }
        self.buttonActionHandler = actionHandler
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
                        currentCategory = .chronoTimestamp // Passe à chronoTimestamp après guardPosition
                    case .chronoTimestamp: // Après chrono, passe à la situation ou termine
                        currentCategory = .situation
                    case .gamjeonType:
                        currentCategory = .chronoTimestamp
                

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
                       currentCategory = .chronoTimestamp // Ajout de chronoTimestamp ici
            case .chronoTimestamp:
                if !(action.actionType == .kick && (points == 2 || points == 4)) {
                    currentCategory = .situation
                } else {
                    onActionComplete?(action)
                    return
                }
                   case .gamjeonType:
                       currentCategory = .chronoTimestamp

            

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
            
        case .chronoTimestamp:
               titleLabel.text = "Enter Remaining Time in Round"
               requestChronoTime()

           case .situation:
               titleLabel.text = "Select Situation"
               addButtons(options: CombatSituation.allCases.map { $0.rawValue }) { [weak self] selectedIndex in
                   self?.action.situation = CombatSituation.allCases[selectedIndex]
                   self?.moveToNextCategory()
               }
        }
    }
}
