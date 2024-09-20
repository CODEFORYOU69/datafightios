//
//  UserMessageCell.swift
//  datafight
//
//  Created by younes ouasmi on 13/09/2024.
//

import UIKit

class UserMessageCell: UITableViewCell {

    let messageLabel = UILabel()
    let bubbleBackgroundView = UIView()
    let avatarImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(bubbleBackgroundView)
        contentView.addSubview(messageLabel)
        contentView.addSubview(avatarImageView)

        
        // Configuration de l'avatar
           avatarImageView.translatesAutoresizingMaskIntoConstraints = false
           avatarImageView.image = UIImage(named: "user_avatar") // Assurez-vous d'avoir une image nommée "bot_avatar"
           avatarImageView.layer.cornerRadius = 15
           avatarImageView.clipsToBounds = true

        // Configuration du messageLabel
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.systemFont(ofSize: 16)


        // Configuration de la bulle de fond
        bubbleBackgroundView.backgroundColor = UIColor.systemBlue
        bubbleBackgroundView.layer.cornerRadius = 16
        bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        bubbleBackgroundView.layer.shadowColor = UIColor.black.cgColor
        bubbleBackgroundView.layer.shadowOpacity = 0.1
        bubbleBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 1)
        bubbleBackgroundView.layer.shadowRadius = 2


        // Contraintes Auto Layout
        NSLayoutConstraint.activate([
                // Contraintes pour avatarImageView
                avatarImageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
                avatarImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
                avatarImageView.widthAnchor.constraint(equalToConstant: 30),
                avatarImageView.heightAnchor.constraint(equalToConstant: 30),
                avatarImageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
                avatarImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                // Ajustez les contraintes de bubbleBackgroundView et messageLabel
                messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
                            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
                            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 16),
                            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -16),

                            // Contraintes pour bubbleBackgroundView (aligné à droite)
                            bubbleBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
                            bubbleBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
                            bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
                            bubbleBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60)
            ])
    }
}
