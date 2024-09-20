//
//  SignUpViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
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
            } else {
                self?.showAlert(message: "Inscription réussie!") {
                    // Naviguer vers l'écran principal de l'application
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
}
