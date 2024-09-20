//
//  UserEditViewController.swift
//  datafight
//
//  Created by younes ouasmi on 16/08/2024.
//

import UIKit
import CountryPickerView
import Photos
import Firebase

class UserEditViewController: UIViewController {
    
    var isNewUser: Bool = false
    var selectedCountryCode: String?

    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var roleTextField: UITextField!
    @IBOutlet weak var teamNameTextField: UITextField!
    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var dateOfBirthPicker: UIDatePicker!
    
    var user: User?
    let countryPicker = CountryPickerView()
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            setupCountryPicker()
            setupImagePicker()
        setupNavigationBar()

            
            if isNewUser {
                navigationItem.hidesBackButton = true
                // Optionnel : Ajouter un message de bienvenue ou des instructions pour le nouvel utilisateur
            }
        }
    

    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
    }
    func setupUI() {
        guard let user = user else { return }
        
        firstNameTextField.text = user.firstName
        lastNameTextField.text = user.lastName
        teamNameTextField.text = user.teamName
        roleTextField.text = user.role
        countryButton.setTitle(user.country, for: .normal)
        
        // Gestion de la date de naissance
        if let dateOfBirth = user.dateOfBirth {
            dateOfBirthPicker.date = dateOfBirth
        } else {
            // Définir une date par défaut si dateOfBirth est nil
            // Par exemple, la date actuelle ou une autre date appropriée
            dateOfBirthPicker.date = Date()
        }
        
        if let imageUrlString = user.profileImageURL, let imageUrl = URL(string: imageUrlString) {
            profileImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_profile"))
        } else {
            profileImageView.image = UIImage(named: "placeholder_profile")
        }
    }
    
    func setupCountryPicker() {
        countryPicker.delegate = self
        countryPicker.dataSource = self
    }
    
    func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    @IBAction func changeProfileImageTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Changer la photo de profil", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Prendre une photo", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            alertController.addAction(cameraAction)
        }
        
        let galleryAction = UIAlertAction(title: "Choisir depuis la galerie", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }
        alertController.addAction(galleryAction)
        
        let cancelAction = UIAlertAction(title: "Annuler", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Configuration pour iPad
        if let popoverController = alertController.popoverPresentationController {
            // Si le bouton qui a déclenché cette action est accessible
            if let button = sender as? UIView {
                popoverController.sourceView = button
                popoverController.sourceRect = button.bounds
            } else {
                // Sinon, utilisez le centre de la vue principale
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            }
            popoverController.permittedArrowDirections = [.up, .down, .left, .right]
        }
        
        present(alertController, animated: true)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .photoLibrary {
            checkPhotoLibraryPermission { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.imagePicker.sourceType = sourceType
                        self?.present(self!.imagePicker, animated: true)
                    }
                } else {
                    self?.showPermissionDeniedAlert()
                }
            }
        } else {
            imagePicker.sourceType = sourceType
            present(imagePicker, animated: true)
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Accès refusé",
            message: "Veuillez autoriser l'accès à votre galerie photos dans les paramètres de l'application pour sélectionner une photo de profil.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    @IBAction func selectCountryTapped(_ sender: Any) {
        countryPicker.showCountriesList(from: self)
    }
    
    @objc  func saveTapped(_ sender: Any) {
        print("Save tapped - début de la méthode")

           guard var updatedUser = user else {
               print("Error: user est nil")
               return
           }
           
           print("Après le guard")

           updatedUser.firstName = firstNameTextField.text ?? ""
           print("FirstName mis à jour")
           updatedUser.lastName = lastNameTextField.text ?? ""
           print("LastName mis à jour")
           updatedUser.role = roleTextField.text ?? ""
           print("Role mis à jour")
           updatedUser.teamName = teamNameTextField.text ?? ""
           print("TeamName mis à jour")
           updatedUser.country = selectedCountryCode ?? ""
           print("Country mis à jour")
           updatedUser.dateOfBirth = dateOfBirthPicker.date
           print("DateOfBirth mis à jour")
           updatedUser.profileImageURL = user?.profileImageURL
           print("ProfileImageURL mis à jour")

           print("Updated user: \(updatedUser)")
        
        FirebaseService.shared.updateUserProfile(updatedUser) { [weak self] result in
                   switch result {
                   case .success:
                       print("Profile updated successfully")
                       self?.showAlert(title: "Succès", message: "Profil mis à jour avec succès") {
                           if self?.isNewUser == true {
                               // Si c'est un nouvel utilisateur, retournez à la racine de la navigation
                               self?.navigationController?.popToRootViewController(animated: true)
                           } else {
                               self?.navigationController?.popViewController(animated: true)
                           }
                       }
                   case .failure(let error):
                       print("Error updating profile: \(error.localizedDescription)")
                       self?.showAlert(title: "Erreur", message: "Impossible de mettre à jour le profil : \(error.localizedDescription)")
                   }
               }
    }
}

extension UserEditViewController: CountryPickerViewDelegate, CountryPickerViewDataSource {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        countryButton.setTitle(country.name, for: .normal)
        selectedCountryCode = country.code
    }
}

extension UserEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
            uploadProfileImage(editedImage)
        }
        picker.dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    func uploadProfileImage(_ image: UIImage) {
        FirebaseService.shared.uploadProfileImage(image) { [weak self] result in
            switch result {
            case .success(let url):
                self?.user?.profileImageURL = url.absoluteString
                print("Profile image uploaded successfully")
                // Après avoir mis à jour l'URL, sauvegardez le profil
                self?.saveUserProfile()
            case .failure(let error):
                print("Error uploading image: \(error.localizedDescription)")
                self?.showAlert(title: "Erreur", message: "Impossible de télécharger l'image : \(error.localizedDescription)")
            }
        }
    }

    private func saveUserProfile() {
        guard let updatedUser = user else { return }
        FirebaseService.shared.updateUserProfile(updatedUser) { [weak self] result in
            switch result {
            case .success:
                print("Profile updated successfully after image upload")
            case .failure(let error):
                print("Error updating profile after image upload: \(error.localizedDescription)")
                self?.showAlert(title: "Erreur", message: "Impossible de mettre à jour le profil après le téléchargement de l'image : \(error.localizedDescription)")
            }
        }
    }
}
extension UserEditViewController {
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized)
                }
            }
        default:
            completion(false)
        }
    }
}
