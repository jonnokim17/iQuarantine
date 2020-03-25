//
//  HomeViewController.swift
//  iQuarantine
//
//  Created by Jonathan Kim on 3/23/20.
//  Copyright © 2020 nomadjonno. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import CoreLocation

class HomeViewController: UIViewController {
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var instructionTextView: UITextView!
    @IBOutlet weak var dayCounterLabel: UILabel!
    @IBOutlet weak var hoursCounterLabel: UILabel!
    @IBOutlet weak var currentDistanceLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var warningLabel: UILabel!
    
    var timeLeft: TimeInterval = 86400
    var timer = Timer()
    
    let db = Firestore.firestore()
    var startDate = Date()
    private var didStartCounter = false
    
    let locationManager = CLLocationManager()
    private let regionInMeters: Double = 1000
    private var locationCheckFlag = false
    private var homeCoordinate = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleFilledButton(startButton)
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if error == nil {
                if let document = document, document.exists {
                    guard let documentData = document.data() else { return }
                    
                    let startedCounter = documentData["startedCounter"] as? Bool ?? false
                    if startedCounter {
                        self.didStartCounter = true
                        self.startTimer(data: documentData)
                    } else {
                        self.startButton.isHidden = false
                        self.instructionTextView.isHidden = false
                        self.warningLabel.isHidden = false
                    }
                    
                    guard let homeLatitude = documentData["latitude"] as? NSNumber else { return }
                    guard let homeLongitude = documentData["longitude"] as? NSNumber else { return }
                    self.homeCoordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(truncating: homeLatitude), longitude: CLLocationDegrees(truncating: homeLongitude))
                }
            }
        }
    }
    
    private func startTimer(data: [String: Any]) {
        guard let timestamp = data["timestamp"] as? Timestamp else {
            self.startButton.isHidden = false
            self.instructionTextView.isHidden = false
            self.warningLabel.isHidden = false
            return
        }
        
        startDate = timestamp.dateValue()
        
        DispatchQueue.main.async {
            self.startButton.isHidden = true
            self.instructionTextView.isHidden = true
            self.warningLabel.isHidden = true
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
        
        let formattedDayString = String(format: "%2ld", day)
        let cleanedFormattedDayString = formattedDayString.replacingOccurrences(of: "-", with: "")
        
        dayCounterLabel.text = "Number of Days: \(cleanedFormattedDayString)"
        
        let formattedHourString = String(format: "%2ld Hours, %2ld Minutes, %2ld Seconds", hour, minute, second)
        let cleanedHourFormattedString = formattedHourString.replacingOccurrences(of: "-", with: "")
        hoursCounterLabel.text = cleanedHourFormattedString
        
        if self.hoursCounterLabel.text != "" && !locationCheckFlag {
            locationCheckFlag = true
            checkLocationServices()
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            mapView.isHidden = false
            setupLocationManager()
            checkLocationAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            mapView.isHidden = true
        }
    }
    
    private func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            centerViewOnUserLocation()
        case .denied:
            mapView.isHidden = true
            let alertController = UIAlertController(title: "Please grant iQuarantine Location Services permissions", message: "", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true)
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            break
        @unknown default:
            break
        }
    }
    
    @IBAction func onStartQuarantine(_ sender: UIButton) {
        currentDistanceLabel.isHidden = false
        dayCounterLabel.isHidden = false
        hoursCounterLabel.isHidden = false
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).setData([
            "timestamp": Date(),
            "startedCounter": true
        ], merge: true) { [weak self] (error) in
            if error == nil {
                self?.startTimer(data: [
                    "timestamp": Timestamp(date: Date())
                ])
                self?.checkLocationServices()
            }
        }
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
        
        if homeCoordinate.latitude != 0 && homeCoordinate.longitude != 0 {
            let homeLocation = CLLocation(latitude: homeCoordinate.latitude, longitude: homeCoordinate.longitude)
            let currentLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let distanceInFeet = homeLocation.distance(from: currentLocation) * 3.281

            currentDistanceLabel.text = String(format: "Distance from home: %.01f Feet", distanceInFeet)
            
            if distanceInFeet <= 200 {
                currentDistanceLabel.textColor = .green
            } else if distanceInFeet <= 800 {
                currentDistanceLabel.textColor = .yellow
            } else if distanceInFeet <= 1200 {
                currentDistanceLabel.textColor = .red
            } else if distanceInFeet >= 2000 {
                currentDistanceLabel.textColor = .red
                let alertController = UIAlertController(title: "Quarantine counter will now reset..", message: "Please return home!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    self.db.collection("users").document(uid).setData([
                        "startedCounter": false
                    ], merge: true) { (error) in
                        DispatchQueue.main.async {
                            self.startButton.isHidden = false
                            self.instructionTextView.isHidden = false
                            self.warningLabel.isHidden = false
                            self.mapView.isHidden = true
                            self.currentDistanceLabel.isHidden = true
                            self.dayCounterLabel.isHidden = true
                            self.hoursCounterLabel.isHidden = true
                            self.didStartCounter = false
                        }
                    }
                }
                alertController.addAction(okAction)
                present(alertController, animated: true)
                return
            }
        }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if error == nil, let placemark = placemarks, !placemark.isEmpty {
                if let placemark = placemark.first {
                    guard let city = placemark.locality else { return }
                    guard let state = placemark.administrativeArea else { return }
                    guard !self.didStartCounter else { return }
                    
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    self.db.collection("users").document(uid).setData([
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude,
                        "homeLocation": "\(city), \(state)"
                    ], merge: true) { (error) in
                        self.didStartCounter = true
                        self.homeCoordinate = location.coordinate
                    }
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
