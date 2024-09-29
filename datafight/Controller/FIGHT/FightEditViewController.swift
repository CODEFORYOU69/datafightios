//
//  FightEditViewController.swift
//  datafight
//
//  Created by younes ouasmi on 18/08/2024.
//

import UIKit
import FirebaseAuth

class FightEditViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var eventPicker: UIPickerView!
    @IBOutlet weak var blueFighterPicker: UIPickerView!
    @IBOutlet weak var redFighterPicker: UIPickerView!
    @IBOutlet weak var isOlympicSegmentedControl: UISegmentedControl!

    @IBOutlet weak var fightNumberInfo: UITextField!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var weightCategoryPicker: UIPickerView!
    @IBOutlet weak var roundPicker: UIPickerView!
    
    

    var events: [Event] = []
    var fighters: [Fighter] = []
    var selectedEvent: Event?
    var selectedBlueFighter: Fighter?
    var selectedRedFighter: Fighter?
    

    let isOlympicOptions = ["Regular", "Olympic"]
    var categories: [String] = []
    var weightCategories: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStyle()

        setupPickers()
        setupIsOlympicSegmentedControl()
        initializeCategoriesAndWeights()
        loadEvents()
        loadFighters()
        title = "Add Fight"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveFightTapped))
        addLabelForPicker(eventPicker, withText: "Event")
        addLabelForPicker(blueFighterPicker, withText: "Blue Fighter")
        addLabelForPicker(redFighterPicker, withText: "Red Fighter")
        addLabelForPicker(categoryPicker, withText: "Category")
        addLabelForPicker(weightCategoryPicker, withText: "Weight")
        addLabelForPicker(roundPicker, withText: "Round")

    }
    
    func setupStyle() {
        view.backgroundColor = .customBackground
        
        // Style pour les UIPickerView
        [eventPicker, blueFighterPicker, redFighterPicker, categoryPicker, weightCategoryPicker, roundPicker].forEach {
            stylePicker($0)
        }
        
        // Style pour le UISegmentedControl
        styleSegmentedControl(isOlympicSegmentedControl)
        
        // Style pour le UITextField
        styleTextField(fightNumberInfo)
        
        // Style pour les boutons de navigation
        navigationItem.leftBarButtonItem?.tintColor = .customAccent
        navigationItem.rightBarButtonItem?.tintColor = .customAccent
    }
    func stylePicker(_ picker: UIPickerView) {
        picker.backgroundColor = .white
        picker.layer.cornerRadius = 10
        picker.layer.borderWidth = 1
        picker.layer.borderColor = UIColor.customAccent.cgColor
        picker.layer.shadowColor = UIColor.black.cgColor
        picker.layer.shadowOffset = CGSize(width: 0, height: 2)
        picker.layer.shadowRadius = 4
        picker.layer.shadowOpacity = 0.1
    }
    func styleSegmentedControl(_ segmentedControl: UISegmentedControl) {
        segmentedControl.backgroundColor = .white
        segmentedControl.selectedSegmentTintColor = .customAccent
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.customText], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.layer.cornerRadius = 10
        segmentedControl.layer.masksToBounds = true
    }

    func styleTextField(_ textField: UITextField) {
        textField.backgroundColor = .white
        textField.textColor = .customText
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.customAccent.cgColor
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowRadius = 4
        textField.layer.shadowOpacity = 0.1
    }
    func addLabelForPicker(_ picker: UIPickerView, withText text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = .customText
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: picker.topAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: picker.leadingAnchor)
        ])
    }
    
    func initializeCategoriesAndWeights() {
        categories = FightCategories.ageCategories
        updateWeightCategories()
    }
    
    func setupIsOlympicSegmentedControl() {
        isOlympicSegmentedControl.removeAllSegments()
        for (index, option) in isOlympicOptions.enumerated() {
            isOlympicSegmentedControl.insertSegment(withTitle: option, at: index, animated: false)
        }
        isOlympicSegmentedControl.selectedSegmentIndex = 0
        isOlympicSegmentedControl.addTarget(self, action: #selector(isOlympicSegmentChanged), for: .valueChanged)
    }
    
    @objc func isOlympicSegmentChanged() {
        updateCategoriesAndWeights()
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    func setupPickers() {
        [eventPicker, blueFighterPicker, redFighterPicker, categoryPicker, weightCategoryPicker, roundPicker].forEach {
            $0?.delegate = self
            $0?.dataSource = self
        }
    }

    func loadEvents() {
        FirebaseService.shared.getEvents { [weak self] result in
            switch result {
            case .success(let events):
                self?.events = events
                print("Loaded events: \(events.map { "ID: \($0.id ?? "nil"), Name: \($0.eventName)" })")
                DispatchQueue.main.async {
                    self?.eventPicker.reloadAllComponents()
                }
            case .failure(let error):
                print("Error loading events: \(error.localizedDescription)")
            }
        }
    }

    func loadFighters() {
        FirebaseService.shared.getFighters { [weak self] result in
            switch result {
            case .success(let fighters):
                self?.fighters = fighters
                print("Loaded fighters: \(fighters.map { "ID: \($0.id ?? "nil"), Name: \($0.firstName) \($0.lastName)" })")
                DispatchQueue.main.async {
                    self?.blueFighterPicker.reloadAllComponents()
                    self?.redFighterPicker.reloadAllComponents()
                }
            case .failure(let error):
                print("Error loading fighters: \(error.localizedDescription)")
            }
        }
    }
    // MARK: - UIPickerViewDataSource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case eventPicker:
            return events.count
        case blueFighterPicker, redFighterPicker:
            return fighters.count
        case categoryPicker:
            return categories.count
        case weightCategoryPicker:
            return weightCategories.count
        case roundPicker:
            return FightCategories.rounds.count
        default:
            return 0
        }
    }

    // MARK: - UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case eventPicker:
            return events[row].eventName
        case blueFighterPicker, redFighterPicker:
            let fighter = fighters[row]
            return "\(fighter.firstName) \(fighter.lastName)"
        case categoryPicker:
            return categories[row]
        case weightCategoryPicker:
            return weightCategories[row]
        case roundPicker:
            return FightCategories.rounds[row]
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case eventPicker:
            selectedEvent = events[row]
        case blueFighterPicker:
            selectedBlueFighter = fighters[row]
            updateCategoriesAndWeights()
        case redFighterPicker:
            selectedRedFighter = fighters[row]
        case categoryPicker:
            updateWeightCategories()
        default:
            break
        }
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textColor = .customText
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18)
        
        switch pickerView {
        case eventPicker:
            label.text = events[row].eventName
        case blueFighterPicker, redFighterPicker:
            let fighter = fighters[row]
            label.text = "\(fighter.firstName) \(fighter.lastName)"
        case categoryPicker:
            label.text = categories[row]
        case weightCategoryPicker:
            label.text = weightCategories[row]
        case roundPicker:
            label.text = FightCategories.rounds[row]
        default:
            break
        }
        
        return label
    }
    func updateCategoriesAndWeights() {
        guard selectedBlueFighter != nil else { return }

        let isOlympic = isOlympicSegmentedControl.selectedSegmentIndex == 1

        if isOlympic {
            categories = ["junior", "senior"]
        } else {
            categories = FightCategories.ageCategories
        }

        DispatchQueue.main.async {
            self.categoryPicker.reloadAllComponents()
            self.categoryPicker.selectRow(0, inComponent: 0, animated: false)
            self.updateWeightCategories()
        }
    }

    func updateWeightCategories() {
        guard let blueFighter = selectedBlueFighter else { return }

        let isOlympic = isOlympicSegmentedControl.selectedSegmentIndex == 1
        let gender = blueFighter.gender.lowercased() == "men" ? "men" : "women"
        let category = categories[categoryPicker.selectedRow(inComponent: 0)]

        if let categoryWeights = FightCategories.weightCategories[isOlympic ? "olympic" : "regular"]?[gender]?[category] {
            weightCategories = categoryWeights
        } else {
            weightCategories = []
        }
        
        print("Is Olympic: \(isOlympic)")
        print("Gender: \(gender)")
        print("Category: \(category)")
        print("Weight Categories: \(weightCategories)")

        DispatchQueue.main.async {
            self.weightCategoryPicker.reloadAllComponents()
        }
    }


    @objc func saveFightTapped(_ sender: Any) {
        guard let event = selectedEvent,
              let blueFighter = selectedBlueFighter,
              let redFighter = selectedRedFighter,
              let fightNumberText = fightNumberInfo.text,
              let fightNumber = Int(fightNumberText),  // Convertir le texte en Int
              let category = categories[safe: categoryPicker.selectedRow(inComponent: 0)],
              let weightCategory = weightCategories[safe: weightCategoryPicker.selectedRow(inComponent: 0)],
              let round = FightCategories.rounds[safe: roundPicker.selectedRow(inComponent: 0)] else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }

        guard let eventId = event.id,
              let blueFighterId = blueFighter.id,
              let redFighterId = redFighter.id,
              let currentUserId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "Invalid event, fighter, or user data")
            return
        }

        let isOlympic = isOlympicSegmentedControl.selectedSegmentIndex == 1
        

        let fight = Fight(
            creatorUserId: currentUserId,
            eventId: eventId,
            fightNumber: fightNumber,
            blueFighterId: blueFighterId,
            redFighterId: redFighterId,
            category: category,
            weightCategory: weightCategory,
            round: round,
            isOlympic: isOlympic
        )

        // Sauvegarder le combat dans Firebase
        FirebaseService.shared.saveFight(fight) { [weak self] result in
            switch result {
            case .success(let fightId):
                // Mettre à jour l'événement et les combattants avec l'ID du combat
                self?.updateEventWithFight(eventId: eventId, fightId: fightId)
                self?.updateFighterWithFight(fighterId: blueFighterId, fightId: fightId)
                self?.updateFighterWithFight(fighterId: redFighterId, fightId: fightId)
                
                // Afficher une alerte de succès et fermer la modal
                DispatchQueue.main.async {
                    self?.showAlert(title: "Success", message: "Fight saved successfully") {
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
            case .failure(let error):
                // Afficher une alerte d'erreur
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to save fight: \(error.localizedDescription)")
                }
            }
        }
    }
    func setupSaveButton() {
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Fight", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .customAccent
        saveButton.layer.cornerRadius = 10
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        saveButton.addTarget(self, action: #selector(saveFightTapped(_:)), for: .touchUpInside)
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    // Méthode helper pour afficher des alertes
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alertController, animated: true, completion: nil)
    }

    func updateEventWithFight(eventId: String, fightId: String) {
        FirebaseService.shared.updateEventWithFight(eventId: eventId, fightId: fightId) { result in
            switch result {
            case .success:
                print("Event updated successfully")
            case .failure(let error):
                print("Error updating event: \(error.localizedDescription)")
            }
        }
    }

    func updateFighterWithFight(fighterId: String, fightId: String) {
        FirebaseService.shared.updateFighterWithFight(fighterId: fighterId, fightId: fightId) { result in
            switch result {
            case .success:
                print("Fighter updated successfully")
            case .failure(let error):
                print("Error updating fighter: \(error.localizedDescription)")
            }
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
extension UIColor {
    static let customBackground = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    static let customAccent = UIColor(red: 0.2, green: 0.6, blue: 0.86, alpha: 1.0)
    static let customText = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
}
