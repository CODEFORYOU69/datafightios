//
//  FighterDetailViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit
import SDWebImage
import FlagKit


class FighterDetailViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var birthdateLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!

    
    
    var fighter: Fighter?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        guard let fighter = fighter else { return }
        
        nameLabel.text = "\(fighter.firstName) \(fighter.lastName)"
        genderLabel.text = "\(fighter.gender)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        if let birthdate = fighter.birthdate {
            birthdateLabel.text = "Birthdate: \(dateFormatter.string(from: birthdate))"
        } else {
            birthdateLabel.text = "Birthdate: Unknown"
        }
        
        countryLabel.text = "Country: \(fighter.country)"
        
        if let imageUrlString = fighter.profileImageURL, let imageUrl = URL(string: imageUrlString) {
            profileImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_profile"))
        } else {
            profileImageView.image = UIImage(named: "placeholder_profile")
        }
        
        if let flag = Flag(countryCode: fighter.country) {
            flagImageView.image = flag.image(style: .roundedRect)
        } else {
            flagImageView.image = nil
        }
        
        // Appliquer le style à l'image de profil
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemBlue.cgColor
    }
}
