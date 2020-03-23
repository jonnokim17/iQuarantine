//
//  HomeViewController.swift
//  iQuarantine
//
//  Created by Jonathan Kim on 3/23/20.
//  Copyright © 2020 nomadjonno. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { (document, error) in
            if error == nil {
                if let document = document, document.exists {
                    guard let documentData = document.data() else { return }
                    guard let name = documentData["firstName"] as? String else { return }
                    
                    DispatchQueue.main.async {
                        self.title = "Welcome \(name)!"
                    }
                }
            }
        }
    }
    
    @IBAction func onStartQuarantine(_ sender: UIButton) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).setData([
            "timestamp": Date()
        ], merge: true)
    }
}
