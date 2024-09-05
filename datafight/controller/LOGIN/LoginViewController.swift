//
//  LoginViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//
import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        // Personnalisez l'apparence de vos éléments UI ici
        loginButton.layer.cornerRadius = 5
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Veuillez remplir tous les champs")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.showAlert(message: "Erreur de connexion: \(error.localizedDescription)")
            } else {
                // Connexion réussie
                self?.performSegue(withIdentifier: "showMainApp", sender: nil)
            }
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }

    // Si vous avez un bouton pour aller à l'écran d'inscription
    @IBAction func goToSignUpButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "showSignUp", sender: nil)
    }
}
