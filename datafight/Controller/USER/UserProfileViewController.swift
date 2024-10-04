import Firebase
import FlagKit
import SDWebImage
//
//  UserProfileViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//
import UIKit

class UserProfileViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    @IBOutlet weak var contentView: UIView!

    // MARK: - Properties
    var user: User?

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserProfile()
        setupNavigationBar()

        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "User Profile"
            ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserProfile()
    }
    func setupNavigationBar() {
        navigationItem.title = "User Profile"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Modify", style: .plain, target: self,
            action: #selector(modifyProfileTapped))

        // Configuration des attributs de la barre de navigation pour le titre en blanc
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]

        // Assurez-vous que le style de la barre est défini pour un texte en blanc
        navigationController?.navigationBar.barStyle = .black
    }
    // MARK: - UI Setup
    private func setupUI() {
        setupViewBackground()
        setupContentView()
        setupProfileImageView()
        setupLabels()
        setupFlagImageView()
    }

    private func setupViewBackground() {
        // Dark background color
        view.backgroundColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
    }

    private func setupContentView() {
        // Content view with dark background and rounded corners
        contentView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        contentView.layer.cornerRadius = 15
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 5)
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowRadius = 10
    }

    private func setupProfileImageView() {
        let size: CGFloat = 120

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: size),
            profileImageView.heightAnchor.constraint(equalToConstant: size),
            profileImageView.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            profileImageView.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: 20),
        ])

        profileImageView.layer.cornerRadius = size / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.contentMode = .scaleAspectFill
    }

    private func setupLabels() {
        // All labels should have white text for contrast against dark background
        [nameLabel, roleLabel, teamNameLabel, countryLabel, dateOfBirthLabel]
            .forEach { label in
                label?.textColor = .white
            }

        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        roleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        [teamNameLabel, countryLabel, dateOfBirthLabel].forEach {
            $0?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }
    }

    private func setupFlagImageView() {
        // Rounded corners for flag image view
        countryFlagImageView.layer.cornerRadius = 5
        countryFlagImageView.clipsToBounds = true
    }

    // MARK: - Data Loading and UI Update
    private func loadUserProfile() {
        FirebaseService.shared.getUserProfile { [weak self] result in
            switch result {
            case .success(let user):
                self?.user = user
                if user.firstName.isEmpty && user.lastName.isEmpty {
                    self?.showEditProfile()
                } else {
                    self?.updateUI(with: user)
                }
            case .failure(let error):
                print("Error loading profile: \(error.localizedDescription)")
                self?.showAlert(
                    title: "Error",
                    message:
                        "Unable to load profile: \(error.localizedDescription)")
            }
        }
    }

    private func updateUI(with user: User) {
        nameLabel.text = "\(user.firstName) \(user.lastName)"
        roleLabel.text = user.role
        teamNameLabel.text = "\(user.teamName)"
        countryLabel.text = "Country: \(user.country)"

        updateFlagImage(for: user.country)
        updateDateOfBirth(user.dateOfBirth)
        updateProfileImage(from: user.profileImageURL)

        // Log user data loaded
        Analytics.logEvent(
            "user_profile_loaded",
            parameters: [
                "has_profile_image": user.profileImageURL != nil
            ])
    }

    private func updateFlagImage(for country: String) {
        if let countryCode = Flag(countryCode: country)?.countryCode {
            let flagImage = Flag(countryCode: countryCode)?.image(
                style: .roundedRect)
            let resizedFlagImage = flagImage?.withRenderingMode(.alwaysOriginal)
                .resized(to: CGSize(width: 60, height: 40))
            countryFlagImageView.image = resizedFlagImage
        } else {
            countryFlagImageView.image = UIImage(named: "placeholder_flag")
        }
    }

    private func updateDateOfBirth(_ date: Date?) {
        if let dateOfBirth = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateOfBirthLabel.text = "\(dateFormatter.string(from: dateOfBirth))"
        } else {
            dateOfBirthLabel.text = "Date of Birth: Not specified"
        }
    }

    private func updateProfileImage(from urlString: String?) {
        if let imageUrlString = urlString,
            let imageUrl = URL(string: imageUrlString)
        {
            profileImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "placeholder_profile"))
        } else {
            profileImageView.image = UIImage(named: "placeholder_profile")
        }
    }

    // MARK: - Navigation
    @objc func modifyProfileTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let editVC = storyboard.instantiateViewController(
            withIdentifier: "UserEditViewController") as? UserEditViewController
        {
            editVC.user = self.user
            navigationController?.pushViewController(editVC, animated: true)

            // Log edit profile action
            Analytics.logEvent("edit_profile_tapped", parameters: nil)
        }
    }

    private func showEditProfile() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let editVC = storyboard.instantiateViewController(
            withIdentifier: "UserEditViewController") as? UserEditViewController
        {
            editVC.user = self.user
            editVC.isNewUser = true
            navigationController?.pushViewController(editVC, animated: true)

            // Log new user edit profile
            Analytics.logEvent("new_user_edit_profile", parameters: nil)
        }
    }

    // MARK: - Helper Methods
    private func showAlert(
        title: String, message: String, completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
        present(alert, animated: true)
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
