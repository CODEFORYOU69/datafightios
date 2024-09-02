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
        
        setupPickers()
        setupIsOlympicSegmentedControl()
        initializeCategoriesAndWeights()
        loadEvents()
        loadFighters()
        title = "Add Fight"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveFightTapped))

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

    func updateCategoriesAndWeights() {
        guard let blueFighter = selectedBlueFighter else { return }

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
