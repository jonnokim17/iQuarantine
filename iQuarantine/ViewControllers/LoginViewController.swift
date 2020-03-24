//
//  LoginViewController.swift
//  iQuarantine
//
//  Created by Jonathan Kim on 3/23/20.
//  Copyright © 2020 nomadjonno. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    private func setupUI() {
        errorLabel.isHidden = true
        
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(loginButton)
    }
    
    private func validateFields() -> String? {
        if emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please fill in all fields."
        }
        
        return nil
    }
    
    private func showError(messsage: String) {
        errorLabel.text = messsage
        errorLabel.isHidden = false
    }
    
    private func navigateToHome() {
        guard let homeViewController = storyboard?.instantiateViewController(identifier: Constants.Storyboard.homeViewController) as? HomeViewController else { return }
        let navVC = UINavigationController(rootViewController: homeViewController)
        view.window?.rootViewController = navVC
        view.window?.makeKeyAndVisible()
    }
    
    private func signIn() {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        guard let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, err) in
            if let err = err {
                self?.showError(messsage: err.localizedDescription)
            } else {
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let db = Firestore.firestore()
                db.collection("users").document(uid).setData([
                    "timestamp": Date()
                ], merge: true) { [weak self] (error) in
                    if error == nil {
                        self?.navigateToHome()
                    }
                }
            }
        }
    }
    
    @IBAction func onLogin(_ sender: UIButton) {
        let error = validateFields()
        
        guard error == nil else {
            showError(messsage: error ?? "")
            return
        }
                
        signIn()
    }
}
