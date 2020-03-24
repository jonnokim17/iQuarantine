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
    @IBOutlet weak var dayCounterLabel: UILabel!
    @IBOutlet weak var hoursCounterLabel: UILabel!
    
    var timeLeft: TimeInterval = 86400
    var endTime: Date?
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
        let endOfDate = Date().endOfDay
        let seconds = endOfDate.timeIntervalSince(Date())
        timeLeft = seconds
        
        guard let timestamp = documentDataDict["timestamp"] as? Timestamp else {
            self.startButton.isHidden = false
            self.timerLabel.text = "00:00:00"
            return
        }
        startDate = timestamp.dateValue()
        
        DispatchQueue.main.async {
            self.startButton.isHidden = true
            self.timerLabel.text = self.timeString(time: self.timeLeft)
            self.endTime = Date().addingTimeInterval(self.timeLeft)
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
        
        startTimer()
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

extension Date {

    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {

        let currentCalendar = Calendar.current

        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }

        return end - start
    }
}
