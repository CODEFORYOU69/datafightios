//
//  FighterEditViewController.swift
//  datafight
//
//  Created by younes ouasmi on 03/08/2024.
//

//
//  FighterEditViewController.swift
//  datafight
//
//  Created by younes ouasmi on 03/08/2024.
//

import UIKit
import CountryPickerView
import Photos
import Firebase
import FirebaseAuth


class FighterEditViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var birthdatePicker: UIDatePicker!
    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var addPhotoButton: UIButton!
    
    var fighter: Fighter?
    var selectedCountryCode: String?
    let countryPicker = CountryPickerView()
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCountryPicker()
        setupImagePicker()
        setupNavigationBar()
    }

    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
    }

    func setupUI() {
        if let fighter = fighter {
            firstNameTextField.text = fighter.firstName
            lastNameTextField.text = fighter.lastName
            genderSegmentedControl.selectedSegmentIndex = fighter.gender == "Male" ? 0 : 1
            countryButton.setTitle(fighter.country, for: .normal)
            
            if let birthdate = fighter.birthdate {
                birthdatePicker.date = birthdate
            } else {
                birthdatePicker.date = Date()
            }
            
            if let imageUrlString = fighter.profileImageURL, let imageUrl = URL(string: imageUrlString) {
                profileImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_profile"))
            } else {
                profileImageView.image = UIImage(named: "placeholder_profile")
            }
        } else {
            birthdatePicker.date = Date()
        }
        
        StyleGuide.applyTextFieldStyle(to: firstNameTextField)
        StyleGuide.applyTextFieldStyle(to: lastNameTextField)
        StyleGuide.applyButtonStyle(to: countryButton)
        StyleGuide.applyButtonStyle(to: addPhotoButton)
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = StyleGuide.Colors.accentColor.cgColor
    }
    
    func setupCountryPicker() {
        countryPicker.delegate = self
        countryPicker.dataSource = self
    }
    
    func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    @IBAction func addPhotoTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Choose a photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Take a photo", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            alertController.addAction(cameraAction)
        }
        
        let galleryAction = UIAlertAction(title: "Choose from gallery", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }
        alertController.addAction(galleryAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender as? UIView
            popoverController.sourceRect = (sender as? UIView)?.bounds ?? .zero
        }
        
        present(alertController, animated: true)
    }

    @IBAction func selectCountryTapped(_ sender: Any) {
        countryPicker.showCountriesList(from: self)
    }
    
    @objc func saveTapped(_ sender: Any) {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let country = selectedCountryCode, !country.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all required fields")
            return
        }
        
        let gender = genderSegmentedControl.selectedSegmentIndex == 0 ? "Male" : "Female"
        
        let updatedFighter = Fighter(
            id: fighter?.id,
            creatorUserId: Auth.auth().currentUser?.uid ?? "",
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            birthdate: birthdatePicker.date,
            country: country,
            profileImageURL: fighter?.profileImageURL
        )
        
        if let image = profileImageView.image, image != UIImage(named: "placeholder_profile") {
            uploadFighterImage(image, fighter: updatedFighter)
        } else {
            saveFighterToFirestore(updatedFighter)
        }
    }
    
    private func uploadFighterImage(_ image: UIImage, fighter: Fighter) {
        FirebaseService.shared.uploadFighterImage(image) { [weak self] result in
            switch result {
            case .success(let url):
                var updatedFighter = fighter
                updatedFighter.profileImageURL = url.absoluteString
                self?.saveFighterToFirestore(updatedFighter)
            case .failure(let error):
                self?.showAlert(title: "Error", message: "Unable to upload image: \(error.localizedDescription)")
            }
        }
    }

    private func saveFighterToFirestore(_ fighter: Fighter) {
        FirebaseService.shared.saveFighter(fighter) { [weak self] result in
            switch result {
            case .success:
                self?.showAlert(title: "Success", message: "Fighter saved successfully") {
                    self?.navigationController?.popViewController(animated: true)
                }
            case .failure(let error):
                self?.showAlert(title: "Error", message: "Unable to save fighter: \(error.localizedDescription)")
            }
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

extension FighterEditViewController: CountryPickerViewDelegate, CountryPickerViewDataSource {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        countryButton.setTitle(country.name, for: .normal)
        selectedCountryCode = country.code
    }
}

extension FighterEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
        }
        picker.dismiss(animated: true)
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
        showAlert(title: "Access Denied", message: "Please allow access to your photo library in the app settings to select a profile picture.")
    }
    
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
