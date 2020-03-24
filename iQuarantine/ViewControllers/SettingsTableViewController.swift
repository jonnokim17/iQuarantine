//
//  SettingsTableViewController.swift
//  iQuarantine
//
//  Created by Jonathan Kim on 3/24/20.
//  Copyright © 2020 nomadjonno. All rights reserved.
//

import UIKit
import Firebase

class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var homeLocationLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupUI()
    }
    
    private func setupUI() {
        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        appVersionLabel.text = "App Version: \(appVersion)"
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if error == nil {
                if let document = document, document.exists {
                    guard let documentData = document.data() else { return }
                    guard let firstName = documentData["firstName"] as? String else { return }
                    guard let lastName = documentData["lastName"] as? String else { return }
                    guard let email = documentData["email"] as? String else { return }
                    guard let homeLocation = documentData["homeLocation"] as? String else { return }
                    
                    DispatchQueue.main.async {
                        self.firstNameLabel.text = firstName
                        self.lastNameLabel.text = lastName
                        self.emailLabel.text = email
                        self.homeLocationLabel.text = homeLocation
                    }
                }
            }
        }
    }
    
    @IBAction func onLogout(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Are you sure you want to logout?", message: "Quarantine clock will reset once you logout.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            
            let db = Firestore.firestore()
            guard let uid = Auth.auth().currentUser?.uid else { return }
            db.collection("users").document(uid).setData([
                "startedCounter": false
            ], merge: true) { [weak self] (error) in
                guard let self = self else { return }
                if error == nil {
                    try? Auth.auth().signOut()
                    if Auth.auth().currentUser == nil {
                        guard let initialViewController = self.storyboard?.instantiateViewController(identifier: Constants.Storyboard.initialViewController) as? InitialViewController else { return }
                        let navVC = UINavigationController(rootViewController: initialViewController)
                        self.view.window?.rootViewController = navVC
                        self.view.window?.makeKeyAndVisible()
                    }
                }
            }
        }
        let noAction = UIAlertAction(title: "No", style: .cancel)
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        present(alertController, animated: true)
    }
}
