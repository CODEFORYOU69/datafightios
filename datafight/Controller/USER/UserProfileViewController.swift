//
//  UserProfileViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit
import SDWebImage
import FlagKit



class UserProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserProfile()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserProfile() // Reload profile when returning from edit screen
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Modify", style: .plain, target: self, action: #selector(modifyProfileTapped))
    }
    
    @objc func modifyProfileTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let editVC = storyboard.instantiateViewController(withIdentifier: "UserEditViewController") as? UserEditViewController {
            editVC.user = self.user
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    func loadUserProfile() {
        FirebaseService.shared.getUserProfile { [weak self] result in
            switch result {
            case .success(let user):
                self?.user = user
                if user.firstName.isEmpty && user.lastName.isEmpty {
                    // Nouvel utilisateur, passez directement à l'écran d'édition
                    self?.showEditProfile()
                } else {
                    self?.updateUI(with: user)
                }
            case .failure(let error):
                print("Error loading profile: \(error.localizedDescription)")
                self?.showAlert(title: "Erreur", message: "Impossible de charger le profil : \(error.localizedDescription)")
            }
        }
    }
    func showEditProfile() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let editVC = storyboard.instantiateViewController(withIdentifier: "UserEditViewController") as? UserEditViewController {
                editVC.user = self.user
                editVC.isNewUser = true // Ajoutez cette propriété à UserEditViewController
                navigationController?.pushViewController(editVC, animated: true)
            }
        }
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    func updateUI(with user: User) {
        firstNameLabel.text = user.firstName
        lastNameLabel.text = user.lastName
        roleLabel.text = user.role
        teamNameLabel.text = user.teamName
        countryLabel.text = user.country
        
        if let countryCode = Flag(countryCode: user.country)?.countryCode {
            let flagImage = Flag(countryCode: countryCode)?.image(style: .roundedRect)
            let resizedFlagImage = flagImage?.withRenderingMode(.alwaysOriginal).resized(to: CGSize(width: 100, height: 60))
            countryFlagImageView.image = resizedFlagImage
        } else {
            countryFlagImageView.image = UIImage(named: "placeholder_flag")
        }

        if let dateOfBirth = user.dateOfBirth {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateOfBirthLabel.text = dateFormatter.string(from: dateOfBirth)
        } else {
            dateOfBirthLabel.text = "Non spécifié"
        }
        
        if let imageUrlString = user.profileImageURL, let imageUrl = URL(string: imageUrlString) {
            profileImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_profile"))
        } else {
            profileImageView.image = UIImage(named: "placeholder_profile")
        }
       
    }
    
    
}
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
