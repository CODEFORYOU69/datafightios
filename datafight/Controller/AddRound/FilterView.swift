//
//  FilterView.swift
//  datafight
//
//  Created by younes ouasmi on 12/09/2024.
//

import UIKit

class FilterView: UIView {
    var attributePicker: UIPickerView!
    var operationPicker: UIPickerView!
    var valueTextField: UITextField!
    var removeButton: UIButton!

    // Initialisation et configuration
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // Configurez vos composants UI ici
        attributePicker = UIPickerView()
        operationPicker = UIPickerView()
        valueTextField = UITextField()
        removeButton = UIButton(type: .system)

        valueTextField.borderStyle = .roundedRect
        removeButton.setTitle("Supprimer", for: .normal)

        // Ajoutez les pickers et le textField à la vue
        addSubview(attributePicker)
        addSubview(operationPicker)
        addSubview(valueTextField)
        addSubview(removeButton)

        // Configurez les contraintes pour les composants (utilisez AutoLayout ou frames)

        // Ajoutez des actions pour le bouton de suppression
        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
    }

    @objc private func removeButtonTapped() {
        self.removeFromSuperview()
    }

    // Méthode pour récupérer le filtre configuré
    func getFilter() -> Filter? {
        // Récupérez les valeurs sélectionnées et créez un objet Filter
        // Assurez-vous de gérer les cas où les sélections ne sont pas complètes
        return Filter(field: selectedAttribute, operation: selectedOperation, value: valueTextField.text ?? "")
    }

    // Propriétés pour stocker les sélections
    private var selectedAttribute: FilterableAttribute = .fighter(.firstName)
    private var selectedOperation: FilterOperation = .equalTo
}

