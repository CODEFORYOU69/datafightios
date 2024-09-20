//
//  DataConfigurationView.swift
//  datafight
//
//  Created by younes ouasmi on 12/09/2024.
//


import UIKit

class DataConfigurationView: UIView, FilterViewDelegate {

    // Outlets connectés depuis le storyboard
 
    @IBOutlet weak var entityTypePicker: UIPickerView!
    @IBOutlet weak var measureTypePicker: UIPickerView!
    @IBOutlet weak var groupByAttributePicker: UIPickerView!
    @IBOutlet weak var filtersStackView: UIStackView!
    @IBOutlet weak var addFilterButton: UIButton!
    @IBOutlet weak var previewButton: UIButton! // Si vous avez un bouton de prévisualisation
    @IBOutlet weak var fighterPicker: UIPickerView!
    @IBOutlet weak var fightPicker: UIPickerView!

    // Propriétés pour stocker les sélections
    private var selectedEntityType: EntityType = .fighter {
        didSet {
            updateGroupByAttributePicker()
            updateFilters()
        }
    }
    private var selectedMeasureType: MeasureType = .count
    private var selectedGroupByAttribute: FilterableAttribute?

    // Autres propriétés
    private var dataConfigurations: [DataConfiguration] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let nib = UINib(nibName: "DataConfigurationView", bundle: nil)
        guard let contentView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupUI() // Assurez-vous que cette ligne est présente

    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        // Configurez les délégués et les data sources
        entityTypePicker.delegate = self
        entityTypePicker.dataSource = self

        measureTypePicker.delegate = self
        measureTypePicker.dataSource = self

        groupByAttributePicker.delegate = self
        groupByAttributePicker.dataSource = self
        
        fighterPicker.delegate = self
            fighterPicker.dataSource = self
            fightPicker.delegate = self
            fightPicker.dataSource = self

            // Charger les données
        

        // Configurez le bouton d'ajout de filtre
        addFilterButton.addTarget(self, action: #selector(addFilterButtonTapped), for: .touchUpInside)

        // Configurez le bouton de prévisualisation si nécessaire
        previewButton.addTarget(self, action: #selector(previewButtonTapped), for: .touchUpInside)
    }
    // Ajouter cette méthode dans ta classe DataConfigurationView
    func configure(with config: DataConfiguration) {
        // Configurer les sélections de base en fonction de la configuration transmise
        selectedEntityType = config.entityType
        selectedMeasureType = config.measure.type
        selectedGroupByAttribute = config.measure.groupBy
        
        // Mettre à jour les pickers en fonction de la configuration
        entityTypePicker.selectRow(EntityType.allCases.firstIndex(of: config.entityType) ?? 0, inComponent: 0, animated: false)
        measureTypePicker.selectRow(MeasureType.allCases.firstIndex(of: config.measure.type) ?? 0, inComponent: 0, animated: false)
        
        // Si un groupBy est présent, sélectionner l'attribut approprié
        if let groupBy = config.measure.groupBy {
            let attributes = getAttributesForSelectedEntityType()
            if let index = attributes.firstIndex(where: { $0 == groupBy }) {
                groupByAttributePicker.selectRow(index, inComponent: 0, animated: false)
            }
        }

        // Configurer les filtres en ajoutant des FilterViews pour chaque filtre
        filtersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() } // Vider les filtres existants
        for filter in config.filters {
            let filterView = FilterView()
            filterView.delegate = self
            filterView.setFilter(filter) // Il te faut ajouter cette méthode pour configurer chaque FilterView
            filtersStackView.addArrangedSubview(filterView)
        }
    }

    @objc func addFilterButtonTapped() {
        let filterView = FilterView()
        filterView.delegate = self // Si vous avez besoin de déléguer des actions
        filtersStackView.addArrangedSubview(filterView)
    }

    @objc func previewButtonTapped() {
        // Implémentez la logique pour la prévisualisation
    }

    func getAllFilters() -> [Filter] {
        return filtersStackView.arrangedSubviews.compactMap { view in
            if let filterView = view as? FilterView {
                return filterView.getFilter()
            }
            return nil
        }
    }

    private func updateGroupByAttributePicker() {
        // Rechargez les données du groupByAttributePicker en fonction de selectedEntityType
        groupByAttributePicker.reloadAllComponents()
    }

    private func updateFilters() {
        // Mettez à jour les filtres existants si nécessaire
    }

}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension DataConfigurationView: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == entityTypePicker {
            return EntityType.allCases.count
        } else if pickerView == measureTypePicker {
            return MeasureType.allCases.count
        } else if pickerView == groupByAttributePicker {
            return getAttributesForSelectedEntityType().count
        } else {
            return 0
        }
    }


    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == entityTypePicker {
            return EntityType.allCases[row].rawValue
        } else if pickerView == measureTypePicker {
            return MeasureType.allCases[row].rawValue
        } else if pickerView == groupByAttributePicker {
            let attribute = getAttributesForSelectedEntityType()[row]
            return attribute.displayName
        } else {
            return nil
        }
    }


    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case entityTypePicker:
            selectedEntityType = EntityType.allCases[row]
        case measureTypePicker:
            selectedMeasureType = MeasureType.allCases[row]
        case groupByAttributePicker:
            selectedGroupByAttribute = getAttributesForSelectedEntityType()[row]
        default:
            break
        }
    }

    private func getAttributesForSelectedEntityType() -> [FilterableAttribute] {
        switch selectedEntityType {
        case .fighter:
            return FighterAttribute.allCases.map { .fighter($0) }
        case .event:
            return EventAttribute.allCases.map { .event($0) }
        case .fight:
            return FightAttribute.allCases.map { .fight($0) }
        case .round:
            return RoundAttribute.allCases.map { .round($0) }
        case .action:
            return ActionAttribute.allCases.map { .action($0) }
        }
    }
    func filterViewDidRequestRemoval(_ filterView: FilterView) {
           filtersStackView.removeArrangedSubview(filterView)
           filterView.removeFromSuperview()
       }
}

