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
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var dayCounterLabel: UILabel!
    @IBOutlet weak var hoursCounterLabel: UILabel!
    
    var timeLeft: TimeInterval = 86400
    var timer = Timer()
    
    let db = Firestore.firestore()
    var documentDataDict: [String: Any]!
    var startDate = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if error == nil {
                if let document = document, document.exists {
                    guard let documentData = document.data() else { return }
                    self.documentDataDict = documentData
                    guard let name = documentData["firstName"] as? String else { return }
                                                                                
                    DispatchQueue.main.async {
                        self.title = "Welcome \(name)!"
                    }
                    
                    self.startTimer()
                }
            }
        }
    }
    
    private func startTimer() {
        guard let timestamp = documentDataDict["timestamp"] as? Timestamp else {
            self.startButton.isHidden = false
            return
        }
        
        startDate = timestamp.dateValue()
        
        DispatchQueue.main.async {
            self.startButton.isHidden = true
            self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
        }
    }
    
    @objc func updateTime() {
        let difference = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: startDate)
        guard let day = difference.day,
            let hour = difference.hour,
            let minute = difference.minute,
            let second = difference.second
        else { return }
        
        let formattedDayString = String(format: "%2ld Days", day)
        let cleanedFormattedDayString = formattedDayString.replacingOccurrences(of: "-", with: "")
        
        dayCounterLabel.text = "Number of Days: \(cleanedFormattedDayString)"
        
        let formattedHourString = String(format: "%02ld Hours, %02ld Minutes, %02ld Seconds", hour, minute, second)
        let cleanedHourFormattedString = formattedHourString.replacingOccurrences(of: "-", with: "")
        hoursCounterLabel.text = cleanedHourFormattedString
    }
    
    @IBAction func onStartQuarantine(_ sender: UIButton) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).setData([
            "timestamp": Date()
        ], merge: true)
        
        startTimer()
    }
}
