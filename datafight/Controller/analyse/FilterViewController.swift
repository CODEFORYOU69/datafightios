    //
    //  FilterViewController.swift
    //  datafight
    //
    //  Created by younes ouasmi on 12/09/2024.
    //

    import UIKit


    protocol FilterViewDelegate: AnyObject {
        func filterViewDidRequestRemoval(_ filterView: FilterView)
        // Vous pouvez ajouter d'autres méthodes si nécessaire
    }

    class FilterView: UIView {

        weak var delegate: FilterViewDelegate?

        @IBOutlet weak var attributePicker: UIPickerView!
        @IBOutlet weak var operationPicker: UIPickerView!
        @IBOutlet weak var valueTextField: UITextField!
        @IBOutlet weak var removeButton: UIButton!

        private var selectedAttribute: FilterableAttribute = .fighter(.firstName)
        private var selectedOperation: FilterOperation = .equalTo

        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            commonInit()
        }

        private func commonInit() {
            // Charger la vue depuis le XIB
            let nib = UINib(nibName: "FilterView", bundle: nil)
            guard let contentView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
                return
            }
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Configuration supplémentaire
            removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)

            // Définir les délégués si nécessaire
            attributePicker.delegate = self
            attributePicker.dataSource = self
            operationPicker.delegate = self
            operationPicker.dataSource = self
        }

        @objc private func removeButtonTapped() {
            delegate?.filterViewDidRequestRemoval(self)
        }

        func getFilter() -> Filter? {
            // Récupérez les valeurs sélectionnées et créez un objet Filter
            return Filter(field: selectedAttribute, operation: selectedOperation, value: valueTextField.text ?? "")
        }
    }

    // Extensions pour UIPickerViewDelegate et UIPickerViewDataSource
    extension FilterView: UIPickerViewDelegate, UIPickerViewDataSource {
        // Implémentez les méthodes nécessaires
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            // Retournez le nombre d'éléments en fonction du pickerView
            // Par exemple :
            if pickerView == attributePicker {
                return FighterAttribute.allCases.count // Ajustez selon vos besoins
            } else if pickerView == operationPicker {
                return FilterOperation.allCases.count
            }
            return 0
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            // Retournez le titre pour chaque ligne
            if pickerView == attributePicker {
                return FighterAttribute.allCases[row].rawValue // Ajustez selon vos besoins
            } else if pickerView == operationPicker {
                return FilterOperation.allCases[row].rawValue
            }
            return nil
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            // Mettez à jour les propriétés sélectionnées
            if pickerView == attributePicker {
                // Mettez à jour selectedAttribute
                selectedAttribute = .fighter(FighterAttribute.allCases[row]) // Ajustez selon vos besoins
            } else if pickerView == operationPicker {
                selectedOperation = FilterOperation.allCases[row]
            }
        }
    }
extension FilterView {
    func setFilter(_ filter: Filter) {
        // Configurer le FilterView avec le filtre donné
        selectedAttribute = filter.field
        selectedOperation = filter.operation
        valueTextField.text = filter.value as? String // Assure-toi que la valeur peut être convertie en String

        // Mise à jour des pickers en fonction des valeurs du filtre
        if let attributeIndex = FighterAttribute.allCases.firstIndex(where: { .fighter($0) == filter.field }) {
            attributePicker.selectRow(attributeIndex, inComponent: 0, animated: false)
        }
        if let operationIndex = FilterOperation.allCases.firstIndex(of: filter.operation) {
            operationPicker.selectRow(operationIndex, inComponent: 0, animated: false)
        }
    }
}
