import Firebase
import FirebaseAuth
import UIKit

class SignUpViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var contentView: UIView!

    // MARK: - Properties
    private var isPasswordVisible = false
    private var isConfirmPasswordVisible = false

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Sign Up"
            ])
    }

    // MARK: - UI Setup
    private func setupUI() {
        applyNeonEffect(to: emailTextField)
        applyNeonEffect(to: passwordTextField)
        applyNeonEffect(to: confirmPasswordTextField)
        applyNeonEffect(to: signUpButton)
        applyNeonEffect(to: contentView)

        // Ensure text is visible in text fields
        [emailTextField, passwordTextField, confirmPasswordTextField].forEach {
            textField in
            textField?.textColor = .black
            textField?.backgroundColor = .white.withAlphaComponent(0.8)
        }

        // Set up secure text entry for password fields
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true

        // Add eye buttons to password fields
        addPasswordToggle(to: passwordTextField)
        addPasswordToggle(to: confirmPasswordTextField)
    }

    // MARK: - IBActions
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty,
            let confirmPassword = confirmPasswordTextField.text,
            !confirmPassword.isEmpty
        else {
            showAlert(message: "Please fill in all fields")
            return
        }

        guard password == confirmPassword else {
            showAlert(message: "Passwords do not match")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) {
            [weak self] authResult, error in
            if let error = error {
                self?.showAlert(
                    message: "Sign up error: \(error.localizedDescription)")

                // Log sign up failure
                Analytics.logEvent(
                    "sign_up_failed",
                    parameters: [
                        "error": error.localizedDescription as NSObject
                    ])
            } else {
                // Log successful sign up
                Analytics.logEvent(
                    AnalyticsEventSignUp,
                    parameters: [
                        AnalyticsParameterMethod: "email" as NSObject
                    ])

                self?.showAlert(message: "Sign up successful!") {
                    self?.performSegue(
                        withIdentifier: "showMainApp", sender: nil)
                }
            }
        }
    }

    // MARK: - Helper Methods
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: nil, message: message, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
        present(alert, animated: true)
    }

    // Function to apply subtle neon effect to the UI elements
    func applyNeonEffect(to view: UIView) {
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
        let textField = sender.superview as! UITextField
        textField.isSecureTextEntry.toggle()

        if textField == passwordTextField {
            isPasswordVisible.toggle()
        } else if textField == confirmPasswordTextField {
            isConfirmPasswordVisible.toggle()
        }

        let imageName = textField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)

        // Log password visibility toggle
        Analytics.logEvent(
            "password_visibility_toggled",
            parameters: [
                "field": textField == passwordTextField
                    ? "password" : "confirm_password" as NSObject,
                "is_visible": !textField.isSecureTextEntry as NSObject,
            ])
    }
}
