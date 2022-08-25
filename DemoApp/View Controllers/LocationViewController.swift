//
//  LocationViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 15/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import AccuTerraSDK

///
/// Basic class for view controllers used for tracking GPS locations
///
class LocationViewController : BaseViewController, LocationServiceDelegate {

    // MARK:- Properties
    // location manager here is only used for permission requests
    private var locationManager = CLLocationManager()
    private var userAuthorizedBgLocations: Bool?
    private var userIgnoredBgLocations: Bool?
    var simulateTrailPath = false
    
    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK:-

    /// Start reporting location changes.
    func startLocationUpdates() {
        if simulateTrailPath, let trailDrive = getTrailDrive() {
            
            //stop location service in case it's running as it will interfere with
            //the simulation
            LocationService.shared.requestingLocationUpdates = false
            
            LocationService.shared.updateLocationSimulator(with: TrailPathLocationSimulator(trailDrive: trailDrive, delegate: self))
            LocationService.shared.startLocationSimulation()
        }
        else {
            LocationService.shared.addHeadingUpdateObserver(observer: self)
            LocationService.shared.addLocationUpdateObserver(observer: self)
            LocationService.shared.requestingLocationUpdates = true
        }
    }

    /// Stops reporting location changes.
    func stopLocationUpdates() {
        if simulateTrailPath {
            LocationService.shared.stopLocationSimulation()
        }
        else {
            LocationService.shared.requestingLocationUpdates = false
        }
    }

    /// Start recording location changes
    func startLocationRecording() {
        LocationService.shared.requestingLocationRecording = true
        LocationService.shared.allowBackgroundLocationUpdates = true
    }

    /// Stops recording location changes
    func stopLocationRecording() {
        LocationService.shared.requestingLocationRecording = false
        LocationService.shared.allowBackgroundLocationUpdates = false
    }
    
    /// Returns the current state of the location permissions needed.
    func hasLocationPermissions() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .denied:
            return false
        default:
            return true
        }
    }
    
    //Base class needs to implement
    func getTrailDrive() -> TrailDrive? {
        return nil
    }

    /// Check if application has locations permissions
    /// and if not it will display an info to request these permissions
    func checkLocationPermissions() {
        if (!hasLocationPermissions()) {
            requestPermissions()
        }
    }
    
    /// Subclass must override this method. Called when location permissions were granted.
    func onLocationPermissionsGranted() {
    }
    
    func requestPermissions() {
        if let userIgnoredBgLocations = self.userIgnoredBgLocations, userIgnoredBgLocations {
            return
        }
        // Provide an additional rationale to the user. This would happen if the user denied the
        // request previously, but didn't tap the "Don't ask again" button.
        
        if let userAuthorizedBgLocations = self.userAuthorizedBgLocations, !userAuthorizedBgLocations, CLLocationManager.authorizationStatus() != .authorizedAlways {
            let alert = UIAlertController(title: "Location Error", message: "Your location is not accessible in background. Please allow the app to Always obtain your location in background for better results.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Allow in Settings", style: .cancel, handler: { (action) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            
            alert.addAction(UIAlertAction(title: "Ignore and don't ask again", style: .default, handler: { (action) in
                self.userIgnoredBgLocations = true
            }))
            
            present(alert, animated: true)
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }

    /// Subclass must override this method. Called when location update is received
    func onLocationUpdated(location: CLLocation) {
    }

    /// Subclass must override this method. Called when heading update is received
    func onHeadingUpdated(heading: CLHeading) {
    }
}

// MARK:- CLLocationManagerDelegate extension
extension LocationViewController : CLLocationManagerDelegate {
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            userAuthorizedBgLocations = false
        }
        else if (status == CLAuthorizationStatus.authorizedAlways) {
            userAuthorizedBgLocations = true
            onLocationPermissionsGranted()
        }
    }
}
