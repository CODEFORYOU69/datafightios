

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
    
    // MARK: - Outlets
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var birthdatePicker: UIDatePicker!
    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var addPhotoButton: UIButton!
    
    // MARK: - Properties
    var fighter: Fighter?
    var selectedCountryCode: String?
    let countryPicker = CountryPickerView()
    let imagePicker = UIImagePickerController()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCountryPicker()
        setupImagePicker()
        setupNavigationBar()
        addParallaxEffect()
    }
    func setupCountryPicker() {
        countryPicker.delegate = self
        countryPicker.dataSource = self}
    
    func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    // MARK: - UI Setup
    func setupUI() {
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        
        setupContentView()
        setupProfileImageView()
        setupTextFields()
        setupGenderSegmentedControl()
        setupBirthdatePicker()
        setupCountryButton()
        setupAddPhotoButton()
        
        populateFields()
    }
    
    func setupContentView() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 15
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 10
    }
    
    func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemBlue.cgColor
    }
    
    func setupTextFields() {
        [firstNameTextField, lastNameTextField].forEach { textField in
            textField?.borderStyle = .none
            textField?.backgroundColor = .systemGray6
            textField?.layer.cornerRadius = 8
            textField?.layer.masksToBounds = true
            textField?.font = UIFont.systemFont(ofSize: 16)
            textField?.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField?.frame.height ?? 0))
            textField?.leftViewMode = .always
        }
    }
    
    func setupGenderSegmentedControl() {
        genderSegmentedControl.backgroundColor = .systemGray6
        genderSegmentedControl.selectedSegmentTintColor = .systemBlue
        genderSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        genderSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
    
    func setupBirthdatePicker() {
        birthdatePicker.backgroundColor = .systemGray6
        birthdatePicker.layer.cornerRadius = 8
    }
    
    func setupCountryButton() {
        countryButton.layer.cornerRadius = 8
        countryButton.backgroundColor = .systemGray6
        countryButton.setTitleColor(.darkGray, for: .normal)
    }
    
    func setupAddPhotoButton() {
        addPhotoButton.layer.cornerRadius = 8
        addPhotoButton.backgroundColor = .systemBlue
        addPhotoButton.setTitleColor(.white, for: .normal)
    }
    
    func populateFields() {
        if let fighter = fighter {
            firstNameTextField.text = fighter.firstName
            lastNameTextField.text = fighter.lastName
            genderSegmentedControl.selectedSegmentIndex = fighter.gender == "Male" ? 0 : 1
            countryButton.setTitle(fighter.country, for: .normal)
            selectedCountryCode = fighter.country
            
            if let birthdate = fighter.birthdate {
                birthdatePicker.date = birthdate
            }
            
            if let imageUrlString = fighter.profileImageURL, let imageUrl = URL(string: imageUrlString) {
                profileImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_profile"))
            }
        }
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
    }
    
    func addParallaxEffect() {
        let amount: CGFloat = 20
        
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -amount
        horizontalMotionEffect.maximumRelativeValue = amount
        
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -amount
        verticalMotionEffect.maximumRelativeValue = amount
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        contentView.addMotionEffect(motionEffectGroup)
    }
    
    // MARK: - Actions
    @IBAction func addPhotoTapped(_ sender: Any) {
        presentPhotoPicker()
    }
    
    @IBAction func selectCountryTapped(_ sender: Any) {
        countryPicker.showCountriesList(from: self)
    }
    
    @objc func saveTapped(_ sender: Any) {
        saveOrUpdateFighter()
    }
    
    // MARK: - Helper Methods
    func presentPhotoPicker() {
        let alertController = UIAlertController(title: "Choose a photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Take a photo", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Choose from gallery", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = addPhotoButton
            popoverController.sourceRect = addPhotoButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    func saveOrUpdateFighter() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let country = selectedCountryCode, !country.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all required fields")
            return
        }
        
        let gender = genderSegmentedControl.selectedSegmentIndex == 0 ? "Men" : "Women"
        
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
    
    func uploadFighterImage(_ image: UIImage, fighter: Fighter) {
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
    
    func saveFighterToFirestore(_ fighter: Fighter) {
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
    
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - Extensions
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
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .photoLibrary {
            checkPhotoLibraryPermission { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.imagePicker.sourceType = sourceType
                        self?.present(self!.imagePicker, animated: true)
                    }
                } else {
                    self?.showAlert(title: "Access Denied", message: "Please allow access to your photo library in the app settings to select a profile picture.")
                }
            }
        } else {
            imagePicker.sourceType = sourceType
            present(imagePicker, animated: true)
        }
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
