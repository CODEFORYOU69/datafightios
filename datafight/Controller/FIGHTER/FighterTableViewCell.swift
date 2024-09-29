//
//  FighterTableViewCell.swift
//  datafight
//
//  Created by younes ouasmi on 17/08/2024.
//

import UIKit
import FlagKit


class FighterTableViewCell: UITableViewCell {
    
    static let preferredHeight: CGFloat = 80 // Ajustez cette valeur selon vos besoins
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add spacing
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        
        // Add rounded corners
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
        
        // Make sure the cell's background is clear so the shadow is visible
        backgroundColor = .clear
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet weak var fighterImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var birthdateLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!

    func configure(with fighter: Fighter) {
        guard let nameLabel = nameLabel else {
               print("Warning: nameLabel is nil")
               return
           }

           // Utilisez la coalescence nulle pour gérer les cas où firstName ou lastName pourrait être nil
           let firstName = fighter.firstName
           let lastName = fighter.lastName
           let gender = fighter.gender
        genderLabel.text = "\(gender)"
           nameLabel.text = "\(firstName) \(lastName)"
        if let imageUrlString = fighter.profileImageURL, let imageUrl = URL(string: imageUrlString) {
            fighterImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_profile"))
        } else {
            fighterImageView.image = UIImage(named: "placeholder_profile")
        }
        
        if let flag = Flag(countryCode: fighter.country) {
            flagImageView.image = flag.image(style: .roundedRect)
        } else {
            flagImageView.image = nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        if let birthdate = fighter.birthdate {
            birthdateLabel.text = dateFormatter.string(from: birthdate)
        } else {
            birthdateLabel.text = "Date de naissance inconnue"
        }

        fighterImageView.layer.cornerRadius = fighterImageView.frame.height / 2
            fighterImageView.clipsToBounds = true

            // Styliser les labels
            nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            birthdateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            birthdateLabel.textColor = .gray

            // Ajuster la taille du drapeau
            flagImageView.contentMode = .scaleAspectFit
        contentView.backgroundColor = .white

    }
    
}
