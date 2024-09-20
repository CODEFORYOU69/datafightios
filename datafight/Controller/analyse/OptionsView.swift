//
//  OptionsView.swift
//  datafight
//
//  Created by younes ouasmi on 13/09/2024.
//

import UIKit

import UIKit

protocol OptionsViewDelegate: AnyObject {
    func optionSelected(_ option: String)
    func optionsValidated(_ selectedOptions: [String])
}


class OptionsView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var delegate: OptionsViewDelegate?

    var options: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var allowsMultipleSelection: Bool = false
    var selectedOptions: [String] = []

    private let collectionView: UICollectionView
    private let validateButton = UIButton()

    override init(frame: CGRect) {
        // Configurer le layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8

        // Initialiser la collectionView
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(OptionCell.self, forCellWithReuseIdentifier: OptionCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelection = allowsMultipleSelection

        addSubview(collectionView)

        // Configurer le bouton de validation
        validateButton.setTitle("Valider", for: .normal)
        validateButton.backgroundColor = .systemBlue
        validateButton.layer.cornerRadius = 10
        validateButton.translatesAutoresizingMaskIntoConstraints = false
        validateButton.addTarget(self, action: #selector(validateSelection), for: .touchUpInside)
        addSubview(validateButton)

        // Contraintes pour collectionView
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            collectionView.bottomAnchor.constraint(equalTo: validateButton.topAnchor, constant: -8),

            validateButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            validateButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            validateButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            validateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Actions

    @objc private func validateSelection() {
        delegate?.optionsValidated(selectedOptions)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OptionCell.identifier, for: indexPath) as? OptionCell else {
            return UICollectionViewCell()
        }

        let option = options[indexPath.item]
        cell.optionLabel.text = option
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let selectedOption = options[indexPath.item]
            delegate?.optionSelected(selectedOption)
        }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let deselectedOption = options[indexPath.item]
        if let index = selectedOptions.firstIndex(of: deselectedOption) {
            selectedOptions.remove(at: index)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let collectionViewWidth = collectionView.bounds.width
        let spacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 8
        let itemsPerRow: CGFloat = 2  // Ajustez ce nombre pour changer le nombre de colonnes
        let totalSpacing = (itemsPerRow - 1) * spacing
        let itemWidth = (collectionViewWidth - totalSpacing) / itemsPerRow

        return CGSize(width: itemWidth, height: 50)
    }
}
