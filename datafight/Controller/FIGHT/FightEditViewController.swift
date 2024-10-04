//
//  FightEditViewController.swift
//  datafight
//
//  Created by younes ouasmi on 18/08/2024.
//

import FirebaseAuth
import UIKit

class FightEditViewController: UIViewController, UIPickerViewDelegate,
    UIPickerViewDataSource
{

    // MARK: - IBOutlets
    @IBOutlet weak var eventPicker: UIPickerView!
    @IBOutlet weak var blueFighterPicker: UIPickerView!
    @IBOutlet weak var redFighterPicker: UIPickerView!
    @IBOutlet weak var isOlympicSegmentedControl: UISegmentedControl!
    @IBOutlet weak var fightNumberInfo: UITextField!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var weightCategoryPicker: UIPickerView!
    @IBOutlet weak var roundPicker: UIPickerView!

    // MARK: - Properties
    var events: [Event] = []
    var fighters: [Fighter] = []
    var selectedEvent: Event?
    var selectedBlueFighter: Fighter?
    var selectedRedFighter: Fighter?

    let isOlympicOptions = ["Regular", "Olympic"]
    var categories: [String] = []
    var weightCategories: [String] = []

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStyle()
        setupPickers()
        setupIsOlympicSegmentedControl()
        initializeCategoriesAndWeights()
        loadEvents()
        loadFighters()
        setupNavigationItems()
        addLabelsForPickers()
    }

    // MARK: - UI Setup Methods
    func setupStyle() {
        // Set the background color (dark background like FilterViewController)
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)

        // Apply styles to pickers, segmented control, text fields, and navigation items
        stylePickers()
        styleSegmentedControl(isOlympicSegmentedControl)
        styleTextField(fightNumberInfo)
        styleNavigationItems()
    }
    private func applyNeonEffect(to view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor  // Neon red
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor
        view.layer.shadowRadius = 3.0
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }

    func stylePickers() {
        // Apply common style to all pickers
        [
            eventPicker, blueFighterPicker, redFighterPicker, categoryPicker,
            weightCategoryPicker, roundPicker,
        ].forEach {
            stylePicker($0)
        }
    }

    func stylePicker(_ picker: UIPickerView) {
        picker.backgroundColor = .black  // Background black
        picker.layer.cornerRadius = 10
        picker.layer.borderWidth = 1
        picker.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor  // Neon red border
        picker.tintColor = .white
        applyNeonEffect(to: picker)  // Neon effect
    }

    func styleSegmentedControl(_ segmentedControl: UISegmentedControl) {
        segmentedControl.backgroundColor = .black
        segmentedControl.selectedSegmentTintColor = UIColor(
            red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8)  // Neon red selected segment
        segmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .normal)
        segmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.black], for: .selected)
        applyNeonEffect(to: segmentedControl)
    }

    func styleTextField(_ textField: UITextField) {
        // Background and text color
        textField.backgroundColor = .black  // Background black
        textField.textColor = .white  // Text white

        // Placeholder text color in white
        if let placeholderText = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholderText,
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ]
            )
        }

        // Border and shadow
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor  // Neon red border
        applyNeonEffect(to: textField)
    }

    func styleNavigationItems() {
        title = "Edit Fight"
        navigationItem.leftBarButtonItem?.tintColor = UIColor(
            red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8)  // Neon red
        navigationItem.rightBarButtonItem?.tintColor = UIColor(
            red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8)
    }
    func addLabelsForPickers() {
        // Add labels for each picker
        addLabelForPicker(eventPicker, withText: "Event")
        addLabelForPicker(blueFighterPicker, withText: "Blue Fighter")
        addLabelForPicker(redFighterPicker, withText: "Red Fighter")
        addLabelForPicker(categoryPicker, withText: "Category")
        addLabelForPicker(weightCategoryPicker, withText: "Weight")
        addLabelForPicker(roundPicker, withText: "Round")
    }
    func addLabelForPicker(_ picker: UIPickerView, withText text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = .white  // Text white for labels
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(
                equalTo: picker.topAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: picker.leadingAnchor),
        ])
    }

    func setupNavigationItems() {
        // Set up navigation bar items
        title = "Add Fight"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel", style: .plain, target: self,
            action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self,
            action: #selector(saveFightTapped))
    }

    // MARK: - Data Loading and Initialization
    func initializeCategoriesAndWeights() {
        // Initialize categories and update weight categories
        categories = FightCategories.ageCategories
        updateWeightCategories()
    }

    func setupIsOlympicSegmentedControl() {
        // Set up the Olympic/Regular segmented control
        isOlympicSegmentedControl.removeAllSegments()
        for (index, option) in isOlympicOptions.enumerated() {
            isOlympicSegmentedControl.insertSegment(
                withTitle: option, at: index, animated: false)
        }
        isOlympicSegmentedControl.selectedSegmentIndex = 0
        isOlympicSegmentedControl.addTarget(
            self, action: #selector(isOlympicSegmentChanged), for: .valueChanged
        )
    }

    func setupPickers() {
        // Set up delegates and data sources for all pickers
        [
            eventPicker, blueFighterPicker, redFighterPicker, categoryPicker,
            weightCategoryPicker, roundPicker,
        ].forEach {
            $0?.delegate = self
            $0?.dataSource = self
        }
    }

    func loadEvents() {
        // Load events from Firebase
        FirebaseService.shared.getEvents { [weak self] result in
            switch result {
            case .success(let events):
                self?.events = events
                DispatchQueue.main.async {
                    self?.eventPicker.reloadAllComponents()
                }
            case .failure(let error):
                print("Error loading events: \(error.localizedDescription)")
            }
        }
    }

    func loadFighters() {
        // Load fighters from Firebase
        FirebaseService.shared.getFighters { [weak self] result in
            switch result {
            case .success(let fighters):
                self?.fighters = fighters
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

    func pickerView(
        _ pickerView: UIPickerView, numberOfRowsInComponent component: Int
    ) -> Int {
        // Return the number of rows for each picker
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
    func pickerView(
        _ pickerView: UIPickerView, titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        // Return the title for each row in the pickers
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

    func pickerView(
        _ pickerView: UIPickerView, didSelectRow row: Int,
        inComponent component: Int
    ) {
        // Handle selection for each picker
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

    func pickerView(
        _ pickerView: UIPickerView, viewForRow row: Int,
        forComponent component: Int, reusing view: UIView?
    ) -> UIView {
        // Customize the appearance of picker rows
        let label = (view as? UILabel) ?? UILabel()
        label.textColor = .white  // Text color white
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

    // MARK: - Helper Methods
    func updateCategoriesAndWeights() {
        // Update categories based on Olympic selection and update weight categories
        guard selectedBlueFighter != nil else { return }

        let isOlympic = isOlympicSegmentedControl.selectedSegmentIndex == 1

        categories =
            isOlympic ? ["junior", "senior"] : FightCategories.ageCategories

        DispatchQueue.main.async {
            self.categoryPicker.reloadAllComponents()
            self.categoryPicker.selectRow(0, inComponent: 0, animated: false)
            self.updateWeightCategories()
        }
    }

    func updateWeightCategories() {
        // Update weight categories based on selected fighter, Olympic status, and category
        guard let blueFighter = selectedBlueFighter else { return }

        let isOlympic = isOlympicSegmentedControl.selectedSegmentIndex == 1
        let gender = blueFighter.gender.lowercased() == "men" ? "men" : "women"
        let category = categories[categoryPicker.selectedRow(inComponent: 0)]

        if let categoryWeights = FightCategories.weightCategories[
            isOlympic ? "olympic" : "regular"]?[gender]?[category]
        {
            weightCategories = categoryWeights
        } else {
            weightCategories = []
        }

        DispatchQueue.main.async {
            self.weightCategoryPicker.reloadAllComponents()
        }
    }

    // MARK: - Action Methods
    @objc func isOlympicSegmentChanged() {
        updateCategoriesAndWeights()
    }

    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func saveFightTapped(_ sender: Any) {
        // Validate and save the fight
        guard let event = selectedEvent,
            let blueFighter = selectedBlueFighter,
            let redFighter = selectedRedFighter,
            let fightNumberText = fightNumberInfo.text,
            let fightNumber = Int(fightNumberText),
            let category = categories[
                safe: categoryPicker.selectedRow(inComponent: 0)],
            let weightCategory = weightCategories[
                safe: weightCategoryPicker.selectedRow(inComponent: 0)],
            let round = FightCategories.rounds[
                safe: roundPicker.selectedRow(inComponent: 0)]
        else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }

        guard let eventId = event.id,
            let blueFighterId = blueFighter.id,
            let redFighterId = redFighter.id,
            let currentUserId = Auth.auth().currentUser?.uid
        else {
            showAlert(
                title: "Error", message: "Invalid event, fighter, or user data")
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

        // Save the fight to Firebase
        FirebaseService.shared.saveFight(fight) { [weak self] result in
            switch result {
            case .success(let fightId):
                // Update event and fighters with the new fight ID
                self?.updateEventWithFight(eventId: eventId, fightId: fightId)
                self?.updateFighterWithFight(
                    fighterId: blueFighterId, fightId: fightId)
                self?.updateFighterWithFight(
                    fighterId: redFighterId, fightId: fightId)

                // Show success alert and dismiss the view controller
                DispatchQueue.main.async {
                    self?.showAlert(
                        title: "Success", message: "Fight saved successfully"
                    ) {
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
            case .failure(let error):
                // Show error alert
                DispatchQueue.main.async {
                    self?.showAlert(
                        title: "Error",
                        message:
                            "Failed to save fight: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Helper Methods
    func showAlert(
        title: String, message: String, completion: (() -> Void)? = nil
    ) {
        let alertController = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
        present(alertController, animated: true, completion: nil)
    }

    func updateEventWithFight(eventId: String, fightId: String) {
        // Update the event with the new fight ID
        FirebaseService.shared.updateEventWithFight(
            eventId: eventId, fightId: fightId
        ) { result in
            switch result {
            case .success:
                print("Event updated successfully")
            case .failure(let error):
                print("Error updating event: \(error.localizedDescription)")
            }
        }
    }

    func updateFighterWithFight(fighterId: String, fightId: String) {
        // Update the fighter with the new fight ID
        FirebaseService.shared.updateFighterWithFight(
            fighterId: fighterId, fightId: fightId
        ) { result in
            switch result {
            case .success:
                print("Fighter updated successfully")
            case .failure(let error):
                print("Error updating fighter: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Extensions
extension Collection {
    // Safe subscript to avoid index out of range errors
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIColor {
    // Custom colors for the app
    static let customBackground = UIColor(
        red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    static let customAccent = UIColor(
        red: 0.2, green: 0.6, blue: 0.86, alpha: 1.0)
    static let customText = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
}
