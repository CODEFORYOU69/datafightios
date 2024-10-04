import Firebase
import UIKit

protocol FilterViewControllerDelegate: AnyObject {
    func didApplyFilters(_ filters: [String: Any])
}

class FilterViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: FilterViewControllerDelegate?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let fighterPicker = UIPickerView()
    private let genderSegmentedControl = UISegmentedControl(items: [
        "Men", "Women",
    ])
    private let countryPicker = UIPickerView()
    private let eventPicker = UIPickerView()
    private let eventTypePicker = UIPickerView()
    private let ageCategoryPicker = UIPickerView()
    private let weightCategoryPicker = UIPickerView()
    private let fightPicker = UIPickerView()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let olympicSegmentedControl = UISegmentedControl(items: [
        "Olympic", "Regular",
    ])

    // Switches to enable/disable filters
    private let fighterSwitch = UISwitch()
    private let genderSwitch = UISwitch()
    private let countrySwitch = UISwitch()
    private let eventSwitch = UISwitch()
    private let eventTypeSwitch = UISwitch()
    private let ageCategorySwitch = UISwitch()
    private let weightCategorySwitch = UISwitch()
    private let fightSwitch = UISwitch()
    private let dateSwitch = UISwitch()
    private let olympicSwitch = UISwitch()

    // Labels for dates
    private let startDateLabel = UILabel()
    private let endDateLabel = UILabel()

    private var fighters: [Fighter] = []
    private var fights: [Fight] = []
    private var countries: [String] = []
    private var events: [Event] = []
    private var eventTypes: [String] = []
    private var ageCategories: [String] = []
    private var weightCategories: [String] = []

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickerDelegates()
        setupUI()
        loadData()

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Filter View"
            ])
    }

    // MARK: - Setup Methods
    private func setupPickerDelegates() {
        let pickers = [
            fighterPicker, countryPicker, eventPicker, eventTypePicker,
            ageCategoryPicker, weightCategoryPicker, fightPicker,
        ]
        for picker in pickers {
            picker.delegate = self
            picker.dataSource = self
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)  // Dark background

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        genderSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        olympicSegmentedControl.translatesAutoresizingMaskIntoConstraints =
            false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        setupSegmentedControls()
        setupPickers()
        setupDatePickers()
        setupApplyButton()

        // Initial state of switches and associated elements
        initializeSwitchesAndControls()
    }

    private func initializeSwitchesAndControls() {
        let switches = [
            fighterSwitch, genderSwitch, countrySwitch, eventSwitch,
            eventTypeSwitch, ageCategorySwitch, weightCategorySwitch,
            fightSwitch, olympicSwitch,
        ]
        let controls: [UIView] = [
            fighterPicker, genderSegmentedControl, countryPicker, eventPicker,
            eventTypePicker, ageCategoryPicker, weightCategoryPicker,
            fightPicker, olympicSegmentedControl,
        ]

        for (filterSwitch, control) in zip(switches, controls) {
            filterSwitch.isOn = false
            setControl(control, enabled: false)
            filterSwitch.addTarget(
                self, action: #selector(switchChanged(_:)), for: .valueChanged)
            filterSwitch.onTintColor = UIColor(
                red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8)  // Neon red
        }

        dateSwitch.isOn = false
        setControl(startDateLabel, enabled: false)
        setControl(startDatePicker, enabled: false)
        setControl(endDateLabel, enabled: false)
        setControl(endDatePicker, enabled: false)
        dateSwitch.addTarget(
            self, action: #selector(switchChanged(_:)), for: .valueChanged)
        dateSwitch.onTintColor = UIColor(
            red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8)  // Neon red
    }

    private func setControl(_ control: UIView, enabled: Bool) {
        control.isUserInteractionEnabled = enabled
        control.alpha = enabled ? 1.0 : 0.5

        if let picker = control as? UIPickerView {
            picker.reloadAllComponents()
        }
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        switch sender {
        case fighterSwitch:
            setControl(fighterPicker, enabled: sender.isOn)
        case genderSwitch:
            setControl(genderSegmentedControl, enabled: sender.isOn)
        case countrySwitch:
            setControl(countryPicker, enabled: sender.isOn)
        case eventSwitch:
            setControl(eventPicker, enabled: sender.isOn)
        case eventTypeSwitch:
            setControl(eventTypePicker, enabled: sender.isOn)
        case ageCategorySwitch:
            setControl(ageCategoryPicker, enabled: sender.isOn)
        case weightCategorySwitch:
            setControl(weightCategoryPicker, enabled: sender.isOn)
        case fightSwitch:
            setControl(fightPicker, enabled: sender.isOn)
        case dateSwitch:
            setControl(startDateLabel, enabled: sender.isOn)
            setControl(startDatePicker, enabled: sender.isOn)
            setControl(endDateLabel, enabled: sender.isOn)
            setControl(endDatePicker, enabled: sender.isOn)
        case olympicSwitch:
            setControl(olympicSegmentedControl, enabled: sender.isOn)
        default:
            break
        }

        // Log filter switch change
        Analytics.logEvent(
            "filter_switch_changed",
            parameters: [
                "filter_type": String(describing: sender),
                "is_enabled": sender.isOn,
            ])
    }

    private func setupSegmentedControls() {
        contentView.addSubview(genderSegmentedControl)
        contentView.addSubview(genderSwitch)

        genderSwitch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            genderSegmentedControl.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: 20),
            genderSegmentedControl.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 20),

            genderSwitch.centerYAnchor.constraint(
                equalTo: genderSegmentedControl.centerYAnchor),
            genderSwitch.leadingAnchor.constraint(
                equalTo: genderSegmentedControl.trailingAnchor, constant: 10),
            genderSwitch.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -20),
        ])

        // Repeat for olympicSegmentedControl and olympicSwitch
        contentView.addSubview(olympicSegmentedControl)
        contentView.addSubview(olympicSwitch)
        olympicSwitch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            olympicSegmentedControl.topAnchor.constraint(
                equalTo: genderSegmentedControl.bottomAnchor, constant: 20),
            olympicSegmentedControl.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 20),

            olympicSwitch.centerYAnchor.constraint(
                equalTo: olympicSegmentedControl.centerYAnchor),
            olympicSwitch.leadingAnchor.constraint(
                equalTo: olympicSegmentedControl.trailingAnchor, constant: 10),
            olympicSwitch.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -20),
        ])

        genderSegmentedControl.addTarget(
            self, action: #selector(genderChanged), for: .valueChanged)
        olympicSegmentedControl.addTarget(
            self, action: #selector(olympicCategoryChanged), for: .valueChanged)
        genderSegmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .normal)
        genderSegmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.black], for: .selected)
        olympicSegmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .normal)
        olympicSegmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.black], for: .selected)

        applyNeonEffect(to: genderSegmentedControl)
        applyNeonEffect(to: olympicSegmentedControl)
    }

    private func setupPickers() {
        let pickers: [(UIPickerView, String, UISwitch)] = [
            (fighterPicker, "Fighter", fighterSwitch),
            (countryPicker, "Country", countrySwitch),
            (eventPicker, "Event", eventSwitch),
            (eventTypePicker, "Event Type", eventTypeSwitch),
            (ageCategoryPicker, "Age Category", ageCategorySwitch),
            (weightCategoryPicker, "Weight Category", weightCategorySwitch),
            (fightPicker, "Fight", fightSwitch),
        ]

        var previousAnchor = olympicSegmentedControl.bottomAnchor

        for (picker, title, filterSwitch) in pickers {
            let label = UILabel()
            label.text = title
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)

            picker.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(picker)

            filterSwitch.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(filterSwitch)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(
                    equalTo: previousAnchor, constant: 20),
                label.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor, constant: 20),

                filterSwitch.centerYAnchor.constraint(
                    equalTo: label.centerYAnchor),
                filterSwitch.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor, constant: -20),

                picker.topAnchor.constraint(
                    equalTo: label.bottomAnchor, constant: 8),
                picker.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor),
                picker.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor),
                picker.heightAnchor.constraint(equalToConstant: 150),
            ])

            previousAnchor = picker.bottomAnchor
            applyNeonEffect(to: picker)

        }
    }

    private func setupDatePickers() {
        var previousAnchor = fightPicker.bottomAnchor

        // Add label and switch for date filter
        let dateFilterLabel = UILabel()
        dateFilterLabel.text = "Date Filter"
        dateFilterLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateFilterLabel)

        dateSwitch.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateSwitch)

        NSLayoutConstraint.activate([
            dateFilterLabel.topAnchor.constraint(
                equalTo: previousAnchor, constant: 20),
            dateFilterLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 20),

            dateSwitch.centerYAnchor.constraint(
                equalTo: dateFilterLabel.centerYAnchor),
            dateSwitch.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -20),
        ])

        previousAnchor = dateFilterLabel.bottomAnchor

        // Add label and picker for start date
        startDateLabel.text = "Start Date"
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(startDateLabel)

        startDatePicker.translatesAutoresizingMaskIntoConstraints = false
        startDatePicker.datePickerMode = .date
        contentView.addSubview(startDatePicker)

        NSLayoutConstraint.activate([
            startDateLabel.topAnchor.constraint(
                equalTo: previousAnchor, constant: 8),
            startDateLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 20),

            startDatePicker.topAnchor.constraint(
                equalTo: startDateLabel.bottomAnchor, constant: 8),
            startDatePicker.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 20),
            startDatePicker.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -20),
        ])

        previousAnchor = startDatePicker.bottomAnchor

        // Add label and picker for end date
        endDateLabel.text = "End Date"
        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(endDateLabel)

        endDatePicker.translatesAutoresizingMaskIntoConstraints = false
        endDatePicker.datePickerMode = .date
        contentView.addSubview(endDatePicker)

        NSLayoutConstraint.activate([
            endDateLabel.topAnchor.constraint(
                equalTo: previousAnchor, constant: 8),
            endDateLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 20),

            endDatePicker.topAnchor.constraint(
                equalTo: endDateLabel.bottomAnchor, constant: 8),
            endDatePicker.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 20),
            endDatePicker.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -20),
        ])

        previousAnchor = endDatePicker.bottomAnchor
        startDateLabel.textColor = .white
        endDateLabel.textColor = .white
        startDatePicker.setValue(UIColor.white, forKey: "textColor")
        endDatePicker.setValue(UIColor.white, forKey: "textColor")
        applyNeonEffect(to: startDatePicker)
        applyNeonEffect(to: endDatePicker)

    }

    private func setupApplyButton() {
        let applyButton = UIButton(type: .system)
        applyButton.setTitle("Apply Filters", for: .normal)
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(applyButton)

        NSLayoutConstraint.activate([
            applyButton.topAnchor.constraint(
                equalTo: endDatePicker.bottomAnchor, constant: 20),
            applyButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            applyButton.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -20),
        ])

        applyButton.addTarget(
            self, action: #selector(applyFilters), for: .touchUpInside)
        applyNeonEffect(to: applyButton)

    }
    private func applyNeonEffect(to view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        view.layer.shadowRadius = 3.0
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 0)

        if let button = view as? UIButton {
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor(
                red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
        }
    }
    private func loadData() {
        let dispatchGroup = DispatchGroup()

        // Loading fighters
        dispatchGroup.enter()
        FirebaseService.shared.getFighters { [weak self] result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let fetchedFighters):
                self?.fighters = fetchedFighters
            case .failure(let error):
                print("Error fetching fighters: \(error)")
            }
        }

        // Loading events
        dispatchGroup.enter()
        FirebaseService.shared.getEvents { [weak self] result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let fetchedEvents):
                self?.events = fetchedEvents
                // Extracting unique event types
                self?.eventTypes = Array(
                    Set(fetchedEvents.map { $0.eventType.rawValue }))
            case .failure(let error):
                print("Error fetching events: \(error)")
            }
        }

        // Loading fights
        dispatchGroup.enter()
        FirebaseService.shared.getFights { [weak self] result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let fetchedFights):
                self?.fights = fetchedFights
                // Extracting unique age categories
                self?.ageCategories = Array(
                    Set(fetchedFights.map { $0.category }))
            case .failure(let error):
                print("Error fetching fights: \(error)")
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.updateFilterData()
        }
    }

    @objc func genderChanged() {
        updateWeightCategories()

        // Log gender change
        Analytics.logEvent(
            "filter_gender_changed",
            parameters: [
                "selected_gender": genderSegmentedControl.selectedSegmentIndex
                    == 0 ? "men" : "women"
            ])
    }

    @objc func olympicCategoryChanged() {
        updateWeightCategories()

        // Log Olympic category change
        Analytics.logEvent(
            "filter_olympic_category_changed",
            parameters: [
                "is_olympic": olympicSegmentedControl.selectedSegmentIndex == 0
            ])
    }

    func pickerView(
        _ pickerView: UIPickerView, didSelectRow row: Int,
        inComponent component: Int
    ) {
        if pickerView == ageCategoryPicker {
            updateWeightCategories()
        }

        // Log picker selection
        Analytics.logEvent(
            "filter_picker_selection",
            parameters: [
                "picker_type": String(describing: type(of: pickerView)),
                "selected_row": row,
            ])
    }

    private func updateFilterData() {
        // Updating fighter countries (nationalities)
        let fighterNationalities = Array(Set(fighters.map { $0.country }))

        // Updating event countries
        let eventCountries = Array(Set(events.map { $0.country }))

        // Combining unique countries
        countries = Array(Set(fighterNationalities + eventCountries))

        // Updating UI components
        fighterPicker.reloadAllComponents()
        countryPicker.reloadAllComponents()
        eventPicker.reloadAllComponents()
        eventTypePicker.reloadAllComponents()
        ageCategoryPicker.reloadAllComponents()

        // Updating weightCategoryPicker based on current selection
        updateWeightCategories()
    }

    private func updateWeightCategories() {
        guard !ageCategories.isEmpty else { return }

        let selectedAgeCategory = ageCategories[
            ageCategoryPicker.selectedRow(inComponent: 0)]
        let selectedGender =
            genderSegmentedControl.selectedSegmentIndex == 0 ? "men" : "women"
        let isOlympic = olympicSegmentedControl.selectedSegmentIndex == 0

        weightCategories = FightCategories.getWeightCategories(
            for: selectedAgeCategory, gender: selectedGender,
            isOlympic: isOlympic)
        weightCategoryPicker.reloadAllComponents()
    }

    @objc private func applyFilters() {
        var filters: [String: Any] = [:]

        if fighterSwitch.isOn {
            filters["fighter"] =
                fighters[fighterPicker.selectedRow(inComponent: 0)].id ?? ""
        }

        if fightSwitch.isOn {
            filters["fight"] =
                fights[fightPicker.selectedRow(inComponent: 0)].id ?? ""
        }

        if genderSwitch.isOn {
            filters["gender"] =
                genderSegmentedControl.selectedSegmentIndex == 0
                ? "men" : "women"
        }

        if countrySwitch.isOn {
            filters["fighterNationality"] =
                countries[countryPicker.selectedRow(inComponent: 0)]
        }

        if eventSwitch.isOn {
            filters["event"] =
                events[eventPicker.selectedRow(inComponent: 0)].id ?? ""
            filters["eventCountry"] =
                events[eventPicker.selectedRow(inComponent: 0)].country
        }

        if eventTypeSwitch.isOn {
            filters["eventType"] =
                eventTypes[eventTypePicker.selectedRow(inComponent: 0)]
        }

        if ageCategorySwitch.isOn {
            filters["ageCategory"] =
                ageCategories[ageCategoryPicker.selectedRow(inComponent: 0)]
        }

        if weightCategorySwitch.isOn {
            filters["weightCategory"] =
                weightCategories[
                    weightCategoryPicker.selectedRow(inComponent: 0)]
        }

        if olympicSwitch.isOn {
            filters["isOlympic"] =
                olympicSegmentedControl.selectedSegmentIndex == 0
        }

        if dateSwitch.isOn {
            filters["startDate"] = startDatePicker.date
            filters["endDate"] = endDatePicker.date
        }

        delegate?.didApplyFilters(filters)
        dismiss(animated: true, completion: nil)

        // Log applied filters
        Analytics.logEvent(
            "filters_applied",
            parameters: [
                "filter_count": filters.count,
                "filter_types": filters.keys.joined(separator: ","),
            ])
    }
}

extension FilterViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(
        _ pickerView: UIPickerView, numberOfRowsInComponent component: Int
    ) -> Int {
        switch pickerView {
        case fighterPicker:
            return fighters.count
        case countryPicker:
            return countries.count
        case eventPicker:
            return events.count
        case eventTypePicker:
            return eventTypes.count
        case ageCategoryPicker:
            return ageCategories.count
        case weightCategoryPicker:
            return weightCategories.count
        case fightPicker:
            return fights.count
        default:
            return 0
        }
    }
    func pickerView(
        _ pickerView: UIPickerView, viewForRow row: Int,
        forComponent component: Int, reusing view: UIView?
    ) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = self.pickerView(
            pickerView, titleForRow: row, forComponent: component)
        return label
    }

    func pickerView(
        _ pickerView: UIPickerView, titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        switch pickerView {
        case fighterPicker:
            let fighter = fighters[row]
            return "\(fighter.firstName) \(fighter.lastName)"
        case countryPicker:
            return countries[row]
        case eventPicker:
            return events[row].eventName
        case eventTypePicker:
            return eventTypes[row]
        case ageCategoryPicker:
            return ageCategories[row]
        case weightCategoryPicker:
            return weightCategories[row]
        case fightPicker:
            return String(fights[row].fightNumber)
        default:
            return nil
        }
    }
}
