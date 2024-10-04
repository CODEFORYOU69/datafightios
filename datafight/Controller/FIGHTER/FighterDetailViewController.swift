//
//  FighterDetailViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import FirebaseAnalytics
import FlagKit
import SDWebImage
import UIKit

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

        // Setup UI and navigation
        setupUI()
        setupNavigationBar()

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Fighter Detail"
            ])
    }

    // MARK: - Setup Navigation Bar
    func setupNavigationBar() {
        navigationController?.navigationBar.barTintColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)  // Same dark background as FightListViewController
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]  // White text for the title
        navigationController?.navigationBar.tintColor = .white  // White back button color
        navigationItem.title =
            "\(fighter?.firstName ?? "") \(fighter?.lastName ?? "")"  // Set the title dynamically based on the fighter's name
    }

    // MARK: - Setup UI
    func setupUI() {
        view.backgroundColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)  // Dark background color

        guard let fighter = fighter else { return }

        // Apply neon effect to labels and image views
        applyNeonEffect(to: nameLabel)
        applyNeonEffect(to: genderLabel)
        applyNeonEffect(to: birthdateLabel)
        applyNeonEffect(to: countryLabel)
        applyNeonEffect(to: profileImageView)

        nameLabel.text = "\(fighter.firstName) \(fighter.lastName)"
        genderLabel.text = "\(fighter.gender)"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        if let birthdate = fighter.birthdate {
            birthdateLabel.text =
                "Birthdate: \(dateFormatter.string(from: birthdate))"
        } else {
            birthdateLabel.text = "Birthdate: Unknown"
        }

        countryLabel.text = "Country: \(fighter.country)"

        if let imageUrlString = fighter.profileImageURL,
            let imageUrl = URL(string: imageUrlString)
        {
            profileImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "placeholder_profile"))
        } else {
            profileImageView.image = UIImage(named: "placeholder_profile")
        }

        if let flag = Flag(countryCode: fighter.country) {
            flagImageView.image = flag.image(style: .roundedRect)
        } else {
            flagImageView.image = nil
        }

        // Apply style to profile image
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
    }

    // Function to apply subtle neon effect to the UI elements
    private func applyNeonEffect(to view: UIView) {
        // Border (subtle neon glow)
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor

        // Shadow for perspective (subtle neon glow)
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        view.layer.shadowRadius = 5.0
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0)

        // Rounded corners
        view.layer.cornerRadius = 10.0

        if let label = view as? UILabel {
            label.textColor = .black  // Changed to black
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.addPadding(left: 8, right: 8, top: 4, bottom: 4)  // Add padding to the label
        }
    }
}

// MARK: - Extension for UILabel padding
extension UILabel {
    func addPadding(
        left: CGFloat = 8, right: CGFloat = 8, top: CGFloat = 4,
        bottom: CGFloat = 4
    ) {
        let insets = UIEdgeInsets(
            top: top, left: left, bottom: bottom, right: right)
        drawText(in: bounds.inset(by: insets))
    }
}
