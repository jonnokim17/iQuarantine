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
    @IBOutlet weak var timerLabel: UILabel!
    
    var timeLeft: TimeInterval = 86400
    var endTime: Date?
    var timer = Timer()
    
    let db = Firestore.firestore()
    var documentDataDict: [String: Any]!
    
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
                    
                    self.startTimer(initialStart: false)
                }
            }
        }
    }
    
    private func startTimer(initialStart: Bool) {
        var startDate: Date
        if initialStart {
            startDate = Date()
        } else {
            guard let timestamp = documentDataDict["timestamp"] as? Timestamp else {
                self.startButton.isHidden = false
                self.timerLabel.text = "00:00:00"
                return
            }
            startDate = timestamp.dateValue()
        }
        
        let endOfDate = Date().endOfDay
        let seconds = endOfDate.timeIntervalSince(startDate)
        self.timeLeft = seconds
        
        DispatchQueue.main.async {
            self.startButton.isHidden = true
            self.timerLabel.text = self.timeString(time: self.timeLeft)
            self.endTime = Date().addingTimeInterval(self.timeLeft)
            self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
        }
    }
    
    @objc func updateTime() {
        if timeLeft > 0 {
            timeLeft = endTime?.timeIntervalSinceNow ?? 0
            timerLabel.text = timeString(time: timeLeft)
        } else {
            timerLabel.text = "00:00"
            timer.invalidate()
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let hour = Int(time) / 3600
        let minute = Int(time) / 60 % 60
        let second = Int(time) % 60

        // return formated string
        return String(format: "%02i:%02i:%02i", hour, minute, second)
    }
    
    @IBAction func onStartQuarantine(_ sender: UIButton) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).setData([
            "timestamp": Date()
        ], merge: true)
        
        startTimer(initialStart: true)
    }
}

extension Date {

    var startOfDay : Date {
        let calendar = Calendar.current
        let unitFlags = Set<Calendar.Component>([.year, .month, .day])
        let components = calendar.dateComponents(unitFlags, from: self)
        return calendar.date(from: components)!
   }

    var endOfDay : Date {
        var components = DateComponents()
        components.day = 1
        let date = Calendar.current.date(byAdding: components, to: self.startOfDay)
        return (date?.addingTimeInterval(-1))!
    }
}
