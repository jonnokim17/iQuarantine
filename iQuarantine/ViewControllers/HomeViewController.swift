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
    @IBOutlet weak var mapView: MKMapView!
    
    var timeLeft: TimeInterval = 86400
    var timer = Timer()
    
    let db = Firestore.firestore()
    var startDate = Date()
    
    let locationManager = CLLocationManager()
    private let regionInMeters: Double = 1000
    private var locationCheckFlag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        Utilities.styleFilledButton(startButton)
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if error == nil {
                if let document = document, document.exists {
                    guard let documentData = document.data() else { return }
                    
                    let startedCounter = documentData["startedCounter"] as? Bool ?? false
                    if startedCounter {
                        self.startTimer(data: documentData)
                    } else {
                        self.startButton.isHidden = false
                        self.instructionTextView.isHidden = false
                    }
                }
            }
        }
    }
    
    private func startTimer(data: [String: Any]) {
        guard let timestamp = data["timestamp"] as? Timestamp else {
            self.startButton.isHidden = false
            self.instructionTextView.isHidden = false
            return
        }
        
        startDate = timestamp.dateValue()
        
        DispatchQueue.main.async {
            self.startButton.isHidden = true
            self.instructionTextView.isHidden = true
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
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).setData([
            "timestamp": Date()
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
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { [weak self] (placemarks, error) in
            if error == nil, let placemark = placemarks, !placemark.isEmpty {
                if let placemark = placemark.first {
                    guard let city = placemark.locality else { return }
                    guard let state = placemark.administrativeArea else { return }
                    
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    self?.db.collection("users").document(uid).setData([
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude,
                        "startedCounter": true,
                        "homeLocation": "\(city), \(state)"
                    ], merge: true)
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
