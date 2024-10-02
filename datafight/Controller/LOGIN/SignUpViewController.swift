import UIKit
import FirebaseAuth
import Firebase

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var contentView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Apply neon effect to the text fields, button, and content view
        applyNeonEffect(to: emailTextField)
        applyNeonEffect(to: passwordTextField)
        applyNeonEffect(to: confirmPasswordTextField)
        applyNeonEffect(to: signUpButton)
        applyNeonEffect(to: contentView)
    }

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(message: "Veuillez remplir tous les champs")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(message: "Les mots de passe ne correspondent pas")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.showAlert(message: "Erreur d'inscription: \(error.localizedDescription)")
            }else {
                // Log a Firebase Analytics event
                Analytics.logEvent("sign_up", parameters: [
                    "email": email as NSObject,
                    "sign_up_method": "email" as NSObject
                ])

                self?.showAlert(message: "Inscription réussie!") {
                    self?.performSegue(withIdentifier: "showMainApp", sender: nil)
                }
            }
        }
    }

    func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    // Function to apply neon effect to the UI elements
    func applyNeonEffect(to view: UIView) {
        // Border (neon glow)
        view.layer.borderWidth = 2.0
        view.layer.borderColor = UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0).cgColor // Pale red color
        
        // Shadow for perspective (neon glow)
        view.layer.shadowColor = UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        view.layer.shadowRadius = 10.0
        view.layer.shadowOpacity = 0.9
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        // Rounded corners
        view.layer.cornerRadius = 10.0

        if let button = view as? UIButton {
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        } else if let textField = view as? UITextField {
            textField.textColor = .white
            textField.font = UIFont.systemFont(ofSize: 16)
        }
    }
}
