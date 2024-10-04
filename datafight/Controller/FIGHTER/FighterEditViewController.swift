import CountryPickerView
import Firebase
import FirebaseAnalytics
import FirebaseAuth
import Photos
import UIKit

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
    private var selectedCountryCode: String?
    private let countryPicker = CountryPickerView()
    private let imagePicker = UIImagePickerController()

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupNavigationBar()

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Fighter Edit"
            ])
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)  // Dark background

        setupContentView()
        setupProfileImageView()
        setupTextFields()
        setupGenderSegmentedControl()
        setupBirthdatePicker()
        setupCountryButton()
        setupAddPhotoButton()

        populateFields()
        addParallaxEffect()
    }

    private func setupContentView() {
        applyNeonEffect(to: contentView)
        contentView.backgroundColor = UIColor(white: 0.1, alpha: 0.8)  // Slightly transparent dark background
    }

    private func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemRed.cgColor
    }

    private func setupTextFields() {
        [firstNameTextField, lastNameTextField].forEach { textField in
            applyNeonEffect(to: textField!)  // Forcer le déballage ici
            textField?.attributedPlaceholder = NSAttributedString(
                string: textField?.placeholder ?? "",
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor.lightGray
                ]
            )
        }
    }

    private func setupGenderSegmentedControl() {
        genderSegmentedControl.backgroundColor = .clear
        genderSegmentedControl.selectedSegmentTintColor = UIColor(
            red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
        genderSegmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .normal)
        genderSegmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.black], for: .selected)
    }

    private func setupBirthdatePicker() {
        birthdatePicker.backgroundColor = .clear
        birthdatePicker.tintColor = .white
        birthdatePicker.setValue(UIColor.white, forKey: "textColor")
    }

    private func setupCountryButton() {
        applyNeonEffect(to: countryButton)
    }

    private func setupAddPhotoButton() {
        applyNeonEffect(to: addPhotoButton)
    }

    private func setupDelegates() {
        countryPicker.delegate = self
        countryPicker.dataSource = self
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self,
            action: #selector(saveTapped))
        navigationController?.navigationBar.tintColor = .white
    }

    private func populateFields() {
        if let fighter = fighter {
            firstNameTextField.text = fighter.firstName
            lastNameTextField.text = fighter.lastName
            genderSegmentedControl.selectedSegmentIndex =
                fighter.gender == "Male" ? 0 : 1
            countryButton.setTitle(fighter.country, for: .normal)
            selectedCountryCode = fighter.country

            if let birthdate = fighter.birthdate {
                birthdatePicker.date = birthdate
            }

            if let imageUrlString = fighter.profileImageURL,
                let imageUrl = URL(string: imageUrlString)
            {
                profileImageView.sd_setImage(
                    with: imageUrl,
                    placeholderImage: UIImage(named: "placeholder_profile"))
            }
        }
    }

    private func addParallaxEffect() {
        let amount: CGFloat = 20
        let group = UIMotionEffectGroup()
        let horizontalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontalEffect.minimumRelativeValue = -amount
        horizontalEffect.maximumRelativeValue = amount

        let verticalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.y", type: .tiltAlongVerticalAxis)
        verticalEffect.minimumRelativeValue = -amount
        verticalEffect.maximumRelativeValue = amount

        group.motionEffects = [horizontalEffect, verticalEffect]
        contentView.addMotionEffect(group)
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
    private func presentPhotoPicker() {
        let alertController = UIAlertController(
            title: "Choose a photo", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(
                UIAlertAction(title: "Take a photo", style: .default) {
                    [weak self] _ in
                    self?.presentImagePicker(sourceType: .camera)
                })
        }

        alertController.addAction(
            UIAlertAction(title: "Choose from gallery", style: .default) {
                [weak self] _ in
                self?.presentImagePicker(sourceType: .photoLibrary)
            })

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel))

        if let popoverController = alertController.popoverPresentationController
        {
            popoverController.sourceView = addPhotoButton
            popoverController.sourceRect = addPhotoButton.bounds
        }

        present(alertController, animated: true)
    }

    private func saveOrUpdateFighter() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
            let lastName = lastNameTextField.text, !lastName.isEmpty,
            let country = selectedCountryCode, !country.isEmpty
        else {
            showAlert(message: "Please fill in all required fields")
            return
        }

        let gender =
            genderSegmentedControl.selectedSegmentIndex == 0 ? "Men" : "Women"

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

        if let image = profileImageView.image,
            image != UIImage(named: "placeholder_profile")
        {
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
                self?.showAlert(
                    message:
                        "Unable to upload image: \(error.localizedDescription)")
            }
        }
    }

    private func saveFighterToFirestore(_ fighter: Fighter) {
        FirebaseService.shared.saveFighter(fighter) { [weak self] result in
            switch result {
            case .success:
                // Log successful fighter save
                Analytics.logEvent(
                    "fighter_saved",
                    parameters: [
                        "fighter_id": fighter.id ?? "new" as NSObject
                    ])
                self?.showAlert(message: "Fighter saved successfully") {
                    self?.navigationController?.popViewController(
                        animated: true)
                }
            case .failure(let error):
                // Log fighter save failure
                Analytics.logEvent(
                    "fighter_save_failed",
                    parameters: [
                        "error": error.localizedDescription as NSObject
                    ])
                self?.showAlert(
                    message:
                        "Unable to save fighter: \(error.localizedDescription)")
            }
        }
    }

    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: nil, message: message, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
        present(alert, animated: true)
    }

    // Function to apply subtle neon effect to the UI elements
    private func applyNeonEffect(to view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        view.layer.shadowRadius = 5.0
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.cornerRadius = 10.0

        if let button = view as? UIButton {
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            button.backgroundColor = UIColor(
                red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
        } else if let textField = view as? UITextField {
            textField.textColor = .white
            textField.font = UIFont.systemFont(ofSize: 16)
            textField.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        }
    }
}

// MARK: - Extensions
extension FighterEditViewController: CountryPickerViewDelegate,
    CountryPickerViewDataSource
{
    func countryPickerView(
        _ countryPickerView: CountryPickerView,
        didSelectCountry country: Country
    ) {
        countryButton.setTitle(country.name, for: .normal)
        selectedCountryCode = country.code
    }
}

extension FighterEditViewController: UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey:
            Any]
    ) {
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
                    self?.showAlert(
                        message:
                            "Please allow access to your photo library in the app settings to select a profile picture."
                    )
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
