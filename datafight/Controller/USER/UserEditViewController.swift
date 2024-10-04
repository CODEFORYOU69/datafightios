//
//  UserEditViewController.swift
//  datafight
//
//  Created by younes ouasmi on 16/08/2024.
//

import CountryPickerView
import Firebase
import Photos
import UIKit

class UserEditViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var roleTextField: UITextField!
    @IBOutlet weak var teamNameTextField: UITextField!
    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var dateOfBirthPicker: UIDatePicker!

    @IBOutlet weak var addPhotoProfileButton: UIButton!
    // MARK: - Properties
    var user: User?
    let countryPicker = CountryPickerView()
    let imagePicker = UIImagePickerController()
    var isNewUser: Bool = false
    var selectedCountryCode: String?

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCountryPicker()
        setupImagePicker()
        setupNavigationBar()

        if isNewUser {
            navigationItem.hidesBackButton = true
        }

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "User Edit Profile"
            ])
    }

    // MARK: - Setup Methods
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .plain, target: self,
            action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.tintColor = .systemBlue
    }

    func setupUI() {
        setupViewBackground()
        setupContentView()
        setupProfileImage()
        setupTextFields()
        setupCountryButton()
        setupDatePicker()
        setupAddPhotoProfileButton()
        populateFieldsIfUserExists()
    }
    func setupAddPhotoProfileButton() {
        // Appliquer les styles similaires au bouton de sélection de pays
        addPhotoProfileButton.layer.cornerRadius = 5
        addPhotoProfileButton.backgroundColor = .black  // Fond noir
        addPhotoProfileButton.setTitleColor(.white, for: .normal)  // Texte blanc
        addPhotoProfileButton.layer.borderWidth = 1
        addPhotoProfileButton.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor  // Bordure néon rouge
        applyNeonEffect(to: addPhotoProfileButton)  // Appliquer l'effet néon
    }
    func setupViewBackground() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)  // Fond noir
    }

    func setupContentView() {
        contentView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)  // Fond gris foncé pour le contenu
        contentView.layer.cornerRadius = 15
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 10
    }

    func setupProfileImage() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
    }

    func setupTextFields() {
        // Pour chaque champ de texte
        [
            firstNameTextField, lastNameTextField, roleTextField,
            teamNameTextField,
        ].forEach { textField in
            textField?.borderStyle = .roundedRect
            textField?.font = UIFont.systemFont(ofSize: 16)
            textField?.backgroundColor = .black  // Fond noir
            textField?.textColor = .white  // Texte blanc

            // Placeholder en blanc
            if let placeholderText = textField?.placeholder {
                textField?.attributedPlaceholder = NSAttributedString(
                    string: placeholderText,
                    attributes: [
                        NSAttributedString.Key.foregroundColor: UIColor.white
                    ]
                )
            }

            // Appliquer l'effet néon pour les bordures
            textField?.layer.cornerRadius = 10
            textField?.layer.borderWidth = 1
            textField?.layer.borderColor =
                UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor  // Bordure néon rouge
            applyNeonEffect(to: textField!)
        }
    }

    func setupCountryButton() {
        // Bouton de sélection de pays avec bordure néon et fond noir
        countryButton.layer.cornerRadius = 5
        countryButton.backgroundColor = .black  // Fond noir
        countryButton.setTitleColor(.white, for: .normal)  // Texte blanc
        countryButton.layer.borderWidth = 1
        countryButton.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor  // Bordure néon rouge
    }

    func setupDatePicker() {
        dateOfBirthPicker.datePickerMode = .date

        // Assurez-vous que le texte de la date est blanc
        dateOfBirthPicker.setValue(UIColor.white, forKey: "textColor")

        // Ajouter la bordure rouge
        dateOfBirthPicker.layer.cornerRadius = 10
        dateOfBirthPicker.layer.borderWidth = 1
        dateOfBirthPicker.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor  // Bordure néon rouge

        // Appliquer l'effet néon si nécessaire
        applyNeonEffect(to: dateOfBirthPicker)
    }

    func applyNeonEffect(to view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor  // Bordure néon rouge
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8).cgColor
        view.layer.shadowRadius = 3.0
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }

    func populateFieldsIfUserExists() {
        guard let user = user else { return }

        firstNameTextField.text = user.firstName
        lastNameTextField.text = user.lastName
        teamNameTextField.text = user.teamName
        roleTextField.text = user.role
        countryButton.setTitle(user.country, for: .normal)
        selectedCountryCode = user.country

        if let dateOfBirth = user.dateOfBirth {
            dateOfBirthPicker.date = dateOfBirth
        }

        if let imageUrlString = user.profileImageURL,
            let imageUrl = URL(string: imageUrlString)
        {
            profileImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "placeholder_profile"))
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

    // MARK: - IBActions
    @IBAction func changeProfileImageTapped(_ sender: Any) {
        let alertController = UIAlertController(
            title: "Change Profile Picture", message: nil,
            preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(
                title: "Take a Photo", style: .default
            ) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            alertController.addAction(cameraAction)
        }

        let galleryAction = UIAlertAction(
            title: "Choose from Gallery", style: .default
        ) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }
        alertController.addAction(galleryAction)

        let cancelAction = UIAlertAction(
            title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        // iPad configuration
        if let popoverController = alertController.popoverPresentationController
        {
            if let button = sender as? UIView {
                popoverController.sourceView = button
                popoverController.sourceRect = button.bounds
            } else {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(
                    x: self.view.bounds.midX, y: self.view.bounds.midY,
                    width: 0, height: 0)
            }
            popoverController.permittedArrowDirections = [
                .up, .down, .left, .right,
            ]
        }

        present(alertController, animated: true)

        // Log profile picture change attempt
        Analytics.logEvent("change_profile_picture_tapped", parameters: nil)
    }

    @IBAction func selectCountryTapped(_ sender: Any) {
        countryPicker.showCountriesList(from: self)

        // Log country selection attempt
        Analytics.logEvent("select_country_tapped", parameters: nil)
    }

    @objc func saveTapped(_ sender: Any) {
        guard var updatedUser = user else {
            print("Error: user is nil")
            return
        }

        updatedUser.firstName = firstNameTextField.text ?? ""
        updatedUser.lastName = lastNameTextField.text ?? ""
        updatedUser.role = roleTextField.text ?? ""
        updatedUser.teamName = teamNameTextField.text ?? ""
        updatedUser.country = selectedCountryCode ?? ""
        updatedUser.dateOfBirth = dateOfBirthPicker.date
        updatedUser.profileImageURL = user?.profileImageURL

        FirebaseService.shared.updateUserProfile(updatedUser) {
            [weak self] result in
            switch result {
            case .success:
                print("Profile updated successfully")
                self?.showAlert(
                    title: "Success", message: "Profile updated successfully"
                ) {
                    if self?.isNewUser == true {
                        self?.navigationController?.popToRootViewController(
                            animated: true)
                    } else {
                        self?.navigationController?.popViewController(
                            animated: true)
                    }
                }

                // Log successful profile update
                Analytics.logEvent("profile_update_success", parameters: nil)
            case .failure(let error):
                print("Error updating profile: \(error.localizedDescription)")
                self?.showAlert(
                    title: "Error",
                    message:
                        "Unable to update profile: \(error.localizedDescription)"
                )

                // Log profile update failure
                Analytics.logEvent(
                    "profile_update_failure",
                    parameters: [
                        "error_description": error.localizedDescription
                    ])
            }
        }
    }

    // MARK: - Helper Methods
    private func presentImagePicker(
        sourceType: UIImagePickerController.SourceType
    ) {
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
            title: "Access Denied",
            message:
                "Please allow access to your photo library in the app settings to select a profile picture.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

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

    private func uploadProfileImage(_ image: UIImage) {
        FirebaseService.shared.uploadProfileImage(image) { [weak self] result in
            switch result {
            case .success(let url):
                self?.user?.profileImageURL = url.absoluteString
                print("Profile image uploaded successfully")
                self?.saveUserProfile()

                // Log successful image upload
                Analytics.logEvent(
                    "profile_image_upload_success", parameters: nil)
            case .failure(let error):
                print("Error uploading image: \(error.localizedDescription)")
                self?.showAlert(
                    title: "Error",
                    message:
                        "Unable to upload image: \(error.localizedDescription)")

                // Log image upload failure
                Analytics.logEvent(
                    "profile_image_upload_failure",
                    parameters: [
                        "error_description": error.localizedDescription
                    ])
            }
        }
    }

    private func saveUserProfile() {
        guard let updatedUser = user else { return }
        FirebaseService.shared.updateUserProfile(updatedUser) {
            [weak self] result in
            switch result {
            case .success:
                print("Profile updated successfully after image upload")
            case .failure(let error):
                print(
                    "Error updating profile after image upload: \(error.localizedDescription)"
                )
                self?.showAlert(
                    title: "Error",
                    message:
                        "Unable to update profile after image upload: \(error.localizedDescription)"
                )
            }
        }
    }
}

// MARK: - CountryPickerViewDelegate, CountryPickerViewDataSource
extension UserEditViewController: CountryPickerViewDelegate,
    CountryPickerViewDataSource
{
    func countryPickerView(
        _ countryPickerView: CountryPickerView,
        didSelectCountry country: Country
    ) {
        countryButton.setTitle(country.name, for: .normal)
        selectedCountryCode = country.code

        // Log country selection
        Analytics.logEvent(
            "country_selected",
            parameters: [
                "country_code": country.code
            ])
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension UserEditViewController: UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey:
            Any]
    ) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
            uploadProfileImage(editedImage)
        }
        picker.dismiss(animated: true)
    }
}

// MARK: - Photo Library Permission
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
