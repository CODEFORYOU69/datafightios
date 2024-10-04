//  EventEditViewController.swift
//  datafight
//
//  Created by younes ouasmi on [DATE]
//

import CountryPickerView
import Firebase
import FirebaseAuth
import UIKit

class EventEditViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var eventTypePicker: UIPickerView!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!

    // MARK: - Properties
    var event: Event?
    let imagePicker = UIImagePickerController()
    let countryPicker = CountryPickerView()
    var selectedCountry: String?

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImagePicker()
        setupEventTypePicker()
        setupCountryPicker()
        setupNavigationBar()
    }

    // MARK: - Setup Methods
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self,
            action: #selector(saveTapped))
    }

    func setupUI() {
        view.backgroundColor = UIColor(
            red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)

        // Setup content view
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 15
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 10

        // Setup image view
        eventImageView.layer.cornerRadius = 10
        eventImageView.clipsToBounds = true
        eventImageView.layer.borderWidth = 2
        eventImageView.layer.borderColor = UIColor.systemBlue.cgColor

        // Setup choose image button
        chooseImageButton.layer.cornerRadius = 5
        chooseImageButton.backgroundColor = .systemBlue
        chooseImageButton.setTitleColor(.white, for: .normal)

        // Setup text fields
        [eventNameTextField, locationTextField].forEach { textField in
            textField?.borderStyle = .none
            textField?.backgroundColor = .systemGray6
            textField?.layer.cornerRadius = 8
            textField?.layer.masksToBounds = true
            textField?.font = UIFont.systemFont(ofSize: 16)
            textField?.leftView = UIView(
                frame: CGRect(
                    x: 0, y: 0, width: 10, height: textField?.frame.height ?? 0)
            )
            textField?.leftViewMode = .always
        }

        // Setup country button
        countryButton.layer.cornerRadius = 8
        countryButton.backgroundColor = .systemGray6
        countryButton.setTitleColor(.darkGray, for: .normal)

        // Setup date picker
        datePicker.backgroundColor = .systemGray6
        datePicker.layer.cornerRadius = 8

        // Populate fields if editing an existing event
        if let event = event {
            populateFields(with: event)
        } else {
            datePicker.date = Date()
        }
    }

    func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }

    func setupEventTypePicker() {
        eventTypePicker.dataSource = self
        eventTypePicker.delegate = self
    }

    func setupCountryPicker() {
        countryPicker.delegate = self
        countryPicker.dataSource = self
    }

    // MARK: - Helper Methods
    private func populateFields(with event: Event) {
        eventNameTextField.text = event.eventName
        if let index = EventType.allCases.firstIndex(of: event.eventType) {
            eventTypePicker.selectRow(index, inComponent: 0, animated: false)
        }
        locationTextField.text = event.location
        datePicker.date = event.date
        selectedCountry = event.country
        countryButton.setTitle(event.country, for: .normal)

        if let imageUrlString = event.imageURL,
            let imageUrl = URL(string: imageUrlString)
        {
            eventImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "placeholder_event"))
        } else {
            eventImageView.image = UIImage(named: "placeholder_event")
        }
    }

    // MARK: - Action Methods
    @IBAction func chooseImageTapped(_ sender: Any) {
        let alertController = UIAlertController(
            title: "Choose a photo", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(
                title: "Take a photo", style: .default
            ) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            alertController.addAction(cameraAction)
        }

        let galleryAction = UIAlertAction(
            title: "Choose from gallery", style: .default
        ) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }
        alertController.addAction(galleryAction)

        let cancelAction = UIAlertAction(
            title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let popoverController = alertController.popoverPresentationController
        {
            popoverController.sourceView = sender as? UIView
            popoverController.sourceRect = (sender as? UIView)?.bounds ?? .zero
        }

        present(alertController, animated: true)
    }

    @IBAction func selectCountryTapped(_ sender: Any) {
        countryPicker.showCountriesList(from: self)
    }

    @objc func saveTapped(_ sender: Any) {
        guard let eventName = eventNameTextField.text, !eventName.isEmpty,
            let location = locationTextField.text, !location.isEmpty,
            let country = selectedCountry, !country.isEmpty
        else {
            showAlert(
                title: "Error", message: "Please fill in all required fields")
            return
        }

        let selectedRow = eventTypePicker.selectedRow(inComponent: 0)
        let eventTypeEnum = EventType.allCases[selectedRow]

        let updatedEvent = Event(
            id: event?.id,
            creatorUserId: Auth.auth().currentUser?.uid ?? "",
            eventName: eventName,
            eventType: eventTypeEnum,
            location: location,
            date: datePicker.date,
            imageURL: event?.imageURL,
            fightIds: event?.fightIds,
            country: country
        )

        if let image = eventImageView.image,
            image != UIImage(named: "placeholder_event")
        {
            uploadEventImage(image, event: updatedEvent)
        } else {
            saveEventToFirestore(updatedEvent)
        }
    }

    // MARK: - Firebase Methods
    private func uploadEventImage(_ image: UIImage, event: Event) {
        FirebaseService.shared.uploadEventImage(image) { [weak self] result in
            switch result {
            case .success(let url):
                var updatedEvent = event
                updatedEvent.imageURL = url.absoluteString
                self?.saveEventToFirestore(updatedEvent)
            case .failure(let error):
                self?.showAlert(
                    title: "Error",
                    message:
                        "Unable to upload image: \(error.localizedDescription)")
            }
        }
    }

    private func saveEventToFirestore(_ event: Event) {
        FirebaseService.shared.saveEvent(event) { [weak self] result in
            switch result {
            case .success:
                self?.showAlert(
                    title: "Success", message: "Event saved successfully"
                ) {
                    self?.navigationController?.popViewController(
                        animated: true)
                }
            case .failure(let error):
                self?.showAlert(
                    title: "Error",
                    message:
                        "Unable to save event: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UI Helpers
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

// MARK: - UIPickerViewDelegate & DataSource
extension EventEditViewController: UIPickerViewDelegate, UIPickerViewDataSource
{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(
        _ pickerView: UIPickerView, numberOfRowsInComponent component: Int
    ) -> Int {
        return EventType.allCases.count
    }

    func pickerView(
        _ pickerView: UIPickerView, titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        return EventType.allCases[row].rawValue
    }
}

// MARK: - CountryPickerViewDelegate & DataSource
extension EventEditViewController: CountryPickerViewDelegate,
    CountryPickerViewDataSource
{
    func countryPickerView(
        _ countryPickerView: CountryPickerView,
        didSelectCountry country: Country
    ) {
        selectedCountry = country.code
        countryButton.setTitle(country.name, for: .normal)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension EventEditViewController: UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey:
            Any]
    ) {
        if let editedImage = info[.editedImage] as? UIImage {
            eventImageView.image = editedImage
        }
        picker.dismiss(animated: true)
    }

    private func presentImagePicker(
        sourceType: UIImagePickerController.SourceType
    ) {
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true)
    }
}
