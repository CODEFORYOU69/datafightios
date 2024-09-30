//
//  LoginViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//
import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTextFields()


        // Ajouter un geste de tap pour fermer le clavier
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    func setupTextFields() {
         emailTextField.delegate = self
         passwordTextField.delegate = self
     }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            loginButtonTapped(textField)
        }
        return true
    }
    @objc func hideKeyboard() {
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
    }

    func setupUI() {
        // Personnalisez l'apparence de vos éléments UI ici
        loginButton.layer.cornerRadius = 5
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(message: "Login error: \(error.localizedDescription)")
                } else {
                    // Connexion réussie
                    self?.handleSuccessfulLogin()
                }
            }
        }
    }
    private func handleSuccessfulLogin() {
          // Use SceneDelegate
          if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
              sceneDelegate.configureInitialViewController()
          }
      }

    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }

    // Signup
    @IBAction func goToSignUpButtonTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "showSignUp", sender: nil)
    }
}
