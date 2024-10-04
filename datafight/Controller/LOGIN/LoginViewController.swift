
//
//  LoginViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//
import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTextFields()
        setupGestures()

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Login"
            ])
    }

    // MARK: - UI Setup
    private func setupUI() {
        applyNeonEffect(to: emailTextField)
        applyNeonEffect(to: passwordTextField)
        applyNeonEffect(to: loginButton)

        // Ensure text is visible in text fields
        [emailTextField, passwordTextField].forEach { textField in
            textField?.textColor = .black
            textField?.backgroundColor = .white.withAlphaComponent(0.8)
        }

        // Set up secure text entry for password field
        passwordTextField.isSecureTextEntry = true

        // Add eye button to password field
        addPasswordToggle(to: passwordTextField)
    }

    private func setupTextFields() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            loginButtonTapped(textField)
        }
        return true
    }

    // MARK: - Actions
    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty
        else {
            showAlert(message: "Please fill in all fields")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) {
            [weak self] authResult, error in
            if let error = error {
                self?.showAlert(
                    message: "Login error: \(error.localizedDescription)")

                // Log login failure
                Analytics.logEvent(
                    "login_failed",
                    parameters: [
                        "error": error.localizedDescription as NSObject
                    ])
            } else {
                // Log successful login
                Analytics.logEvent(
                    AnalyticsEventLogin,
                    parameters: [
                        AnalyticsParameterMethod: "email" as NSObject
                    ])

                self?.handleSuccessfulLogin()
            }
        }
    }

    @IBAction func goToSignUpButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "showSignUp", sender: nil)

        // Log sign up button tap
        Analytics.logEvent("sign_up_button_tapped", parameters: nil)
    }

    // MARK: - Helper Methods
    private func handleSuccessfulLogin() {
        if let sceneDelegate = view.window?.windowScene?.delegate
            as? SceneDelegate
        {
            sceneDelegate.configureInitialViewController()
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: nil, message: message, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }

    // Function to apply subtle neon effect to the UI elements
    private func applyNeonEffect(to view: UIView) {
        // Border (subtle neon glow)
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor  // Pale red color with reduced opacity

        // Shadow for perspective (subtle neon glow)
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        view.layer.shadowRadius = 5.0
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0)

        // Rounded corners
        view.layer.cornerRadius = 10.0

        if let button = view as? UIButton {
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            button.backgroundColor = UIColor(
                red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)  // Darker red for button
        } else if let textField = view as? UITextField {
            textField.textColor = .black
            textField.font = UIFont.systemFont(ofSize: 16)
            textField.backgroundColor = .white.withAlphaComponent(0.8)
        }
    }

    // Function to add password toggle button
    private func addPasswordToggle(to textField: UITextField) {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.tintColor = .darkGray
        button.addTarget(
            self, action: #selector(togglePasswordVisibility),
            for: .touchUpInside)

        textField.rightView = button
        textField.rightViewMode = .always
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()

        let imageName =
            passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)

        // Log password visibility toggle
        Analytics.logEvent(
            "password_visibility_toggled",
            parameters: [
                "is_visible": !passwordTextField.isSecureTextEntry as NSObject
            ])
    }
}
