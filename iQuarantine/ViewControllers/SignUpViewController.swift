//
//  SignUpViewController.swift
//  iQuarantine
//
//  Created by Jonathan Kim on 3/23/20.
//  Copyright © 2020 nomadjonno. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func validateFields() -> String? {
        if firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please fill in all fields."
        }
        
        guard let cleanedPassword = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return "No password" }
        if !Utilities.isPasswordValid(cleanedPassword) {
            return "Please make sure your password is at least 8 characters, contains a special character, and a number."
        }
        
        return nil
    }
    
    private func setupUI() {
        errorLabel.isHidden = true
        
        Utilities.styleTextField(firstNameTextField)
        Utilities.styleTextField(lastNameTextField)
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(signUpButton)
    }
    
    private func showError(messsage: String) {
        errorLabel.text = messsage
        errorLabel.isHidden = false
    }
    
    private func navigateToHome() {
        guard let homeViewController = storyboard?.instantiateViewController(identifier: Constants.Storyboard.homeTabBarController) as? UITabBarController else { return }
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    @IBAction func onSignUp(_ sender: UIButton) {
        let error = validateFields()
        
        guard error == nil else {
            showError(messsage: error ?? "")
            return
        }
        
        guard let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        guard let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result, err) in
            if let _ = err {
                self?.showError(messsage: "Error creating user.")
            } else {
                guard let result = result else { return }
                let db = Firestore.firestore()
                db.collection("users").document("\(result.user.uid)").setData([
                    "firstName": firstName,
                    "lastName": lastName,
                    "uid": result.user.uid,
                    "email": email
                ]) { (err) in
                    if let err = err {
                        self?.showError(messsage: "Error: \(err.localizedDescription)")
                    }
                }
                
                self?.navigateToHome()
            }
        }
    }
}
