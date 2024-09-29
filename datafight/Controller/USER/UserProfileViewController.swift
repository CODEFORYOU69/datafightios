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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    @IBOutlet weak var contentView: UIView!


    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserProfile()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserProfile()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
           view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
           
           // Setup content view
           contentView.backgroundColor = .white
           contentView.layer.cornerRadius = 15
           contentView.layer.shadowColor = UIColor.black.cgColor
           contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
           contentView.layer.shadowOpacity = 0.1
           contentView.layer.shadowRadius = 10
           
        setupProfileImageView()

           
           // Setup labels
           [nameLabel, roleLabel, teamNameLabel, countryLabel, dateOfBirthLabel].forEach { label in
               label?.textColor = .darkGray
           }
           
           nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
           roleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
           [teamNameLabel, countryLabel, dateOfBirthLabel].forEach { label in
               label?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
           }
           
           // Setup flag image
           countryFlagImageView.layer.cornerRadius = 5
           countryFlagImageView.clipsToBounds = true
       }
    
    func setupProfileImageView() {
        // Définir une taille fixe pour l'image de profil
        let size: CGFloat = 120 // Vous pouvez ajuster cette valeur selon vos besoins
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: size),
            profileImageView.heightAnchor.constraint(equalToConstant: size),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20)
        ])
        
        profileImageView.layer.cornerRadius = size / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        
        profileImageView.contentMode = .scaleAspectFill // Ceci assurera que l'image remplit le cercle sans déformation
    }
    
       
    private func updateUI(with user: User) {
           nameLabel.text = "\(user.firstName) \(user.lastName)"
           roleLabel.text = user.role
           teamNameLabel.text = "Team: \(user.teamName)"
           countryLabel.text = "Country: \(user.country)"
           
           if let countryCode = Flag(countryCode: user.country)?.countryCode {
               let flagImage = Flag(countryCode: countryCode)?.image(style: .roundedRect)
               let resizedFlagImage = flagImage?.withRenderingMode(.alwaysOriginal).resized(to: CGSize(width: 60, height: 40))
               countryFlagImageView.image = resizedFlagImage
           } else {
               countryFlagImageView.image = UIImage(named: "placeholder_flag")
           }

           if let dateOfBirth = user.dateOfBirth {
               let dateFormatter = DateFormatter()
               dateFormatter.dateStyle = .medium
               dateOfBirthLabel.text = "Date of Birth: \(dateFormatter.string(from: dateOfBirth))"
           } else {
               dateOfBirthLabel.text = "Date of Birth: Not specified"
           }
           
           if let imageUrlString = user.profileImageURL, let imageUrl = URL(string: imageUrlString) {
               profileImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_profile"))
           } else {
               profileImageView.image = UIImage(named: "placeholder_profile")
           }
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
      
    
}
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
