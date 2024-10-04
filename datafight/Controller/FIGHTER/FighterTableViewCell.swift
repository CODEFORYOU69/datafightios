//
//  FighterTableViewCell.swift
//  datafight
//
//  Created by younes ouasmi on 17/08/2024.
//

import FirebaseAnalytics
import FlagKit
import UIKit

class FighterTableViewCell: UITableViewCell {

    static let preferredHeight: CGFloat = 80

    @IBOutlet weak var fighterImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var birthdateLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()

        // Add spacing
        contentView.frame = contentView.frame.inset(
            by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))

        // Add rounded corners
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        // Add shadow and neon effect
        layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.5
        layer.masksToBounds = false
        layer.shadowPath =
            UIBezierPath(
                roundedRect: bounds,
                cornerRadius: contentView.layer.cornerRadius
            ).cgPath

        // Make sure the cell's background is clear so the shadow is visible
        backgroundColor = .clear

        // Apply neon effect
        applyNeonEffect(to: contentView)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleLabels()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    private func styleLabels() {
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = .white

        birthdateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        birthdateLabel.textColor = .lightGray

        genderLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        genderLabel.textColor = .lightGray
    }

    func configure(with fighter: Fighter) {
        guard let nameLabel = nameLabel else {
            print("Warning: nameLabel is nil")
            return
        }

        let firstName = fighter.firstName
        let lastName = fighter.lastName
        let gender = fighter.gender
        genderLabel.text = "\(gender)"
        nameLabel.text = "\(firstName) \(lastName)"

        if let imageUrlString = fighter.profileImageURL,
            let imageUrl = URL(string: imageUrlString)
        {
            fighterImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "placeholder_profile"))
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
        fighterImageView.layer.borderWidth = 2
        fighterImageView.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor

        flagImageView.contentMode = .scaleAspectFit
        contentView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)

        // Log fighter cell configuration
        Analytics.logEvent(
            "fighter_cell_configured",
            parameters: [
                "fighter_id": fighter.id ?? "unknown" as NSObject,
                "fighter_name": "\(firstName) \(lastName)" as NSObject,
                "fighter_country": fighter.country as NSObject,
            ])
    }

    // Function to apply subtle neon effect to the UI elements
    private func applyNeonEffect(to view: UIView) {
        // Border (subtle neon glow)
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor

        // Shadow for perspective (subtle neon glow)
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        view.layer.shadowRadius = 3.0
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
}
