//
//  OptionCell.swift
//  datafight
//
//  Created by younes ouasmi on 14/09/2024.
//

import UIKit

class OptionCell: UICollectionViewCell {
    static let identifier = "OptionCell"

    let optionLabel = UILabel()

    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? .systemBlue : .lightGray
            optionLabel.textColor = isSelected ? .white : .black
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(optionLabel)
        optionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            optionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            optionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            optionLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = .lightGray
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
