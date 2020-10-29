//
//  LocationService.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 15/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import CoreLocation
import AccuTerraSDK
import Mapbox

protocol LocationServiceDelegate {
    func onLocationUpdated(location: CLLocation)
    func onHeadingUpdated(heading: CLHeading)
}


/// Service used for gathering location updates, recording these with the [ITripRecorder]
/// and broadcasting these via the default NotificationCenter
class LocationService : NSObject, MGLLocationManager {

    var delegate: MGLLocationManagerDelegate?
    private let TAG = "LocationService"
    private let KEY_REQUESTING_LOCATION_RECORDING = "KEY_REQUESTING_LOCATION_RECORDING"

    var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    func requestAlwaysAuthorization() {
        requestingLocationUpdates = true
    }

    func requestWhenInUseAuthorization() {
        requestingLocationUpdates = true
    }

    func startUpdatingLocation() {
        requestingLocationUpdates = true
    }

    func stopUpdatingLocation() {
        requestingLocationUpdates = false
    }

    var headingOrientation: CLDeviceOrientation {
        get {
            locationManager.headingOrientation
        }
        set {
            locationManager.headingOrientation = newValue
        }
    }

    func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }

    func dismissHeadingCalibrationDisplay() {
        // not implemented
    }

    private var locationManager = CLLocationManager()

    private let notificationCenter = NotificationCenter.default

    private var lastReportedLocation: CLLocation?
    private var lastReportedHeading: CLHeading?

    private(set) var recorder: ITripRecorder!

    // MARK:- NOTIFICATIONS

    public func addLocationUpdateObserver(observer: LocationServiceDelegate) {
        notificationCenter.addObserver(forName: LocationUpdatedNotification.Name, object: self, queue: nil) { notification in
            if let notification: LocationUpdatedNotification = notification.getLocationServiceNotification() {
                observer.onLocationUpdated(location: notification.location)
            }
        }
    }

    public func removeLocationUpdateObserver(observer: LocationServiceDelegate) {
        notificationCenter.removeObserver(observer, name: LocationUpdatedNotification.Name, object: self)
    }

    public func addHeadingUpdateObserver(observer: LocationServiceDelegate) {
        notificationCenter.addObserver(forName: HeadingUpdatedNotification.Name, object: self, queue: nil) { notification in
            if let notification: HeadingUpdatedNotification = notification.getLocationServiceNotification() {
                observer.onHeadingUpdated(heading: notification.heading)
            }
        }
    }

    public func removeHeadingUpdateObserver(observer: LocationServiceDelegate) {
        notificationCenter.removeObserver(observer, name: HeadingUpdatedNotification.Name, object: self)
    }
    
    var requestingLocationUpdates: Bool = false
    {
        didSet {
            if requestingLocationUpdates {
                locationManager.delegate = self
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.showsBackgroundLocationIndicator = true
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingHeading()
                locationManager.startUpdatingLocation()
            } else {
                locationManager.stopUpdatingHeading()
                locationManager.stopUpdatingLocation()
            }
        }
    }
    
    var requestingLocationRecording: Bool {
        get {
            UserDefaults.standard.bool(forKey: KEY_REQUESTING_LOCATION_RECORDING)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: KEY_REQUESTING_LOCATION_RECORDING)
        }
    }
    
    public static var shared: LocationService = {
        LocationService()
    }()
    
    private override init() {
        super.init()
        recorder = try! ServiceFactory.getTripRecorder()
    }
}

extension LocationService : CLLocationManagerDelegate {

    /// This is the main method where new locations are reported.
    /// - records new location into the ITripRecorded if requested
    /// - broadcasts new location for potential listeners through notification center
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        Log.d(TAG, "CURRENT LOCATION: \(currentLocation)")
        
        lastReportedLocation = currentLocation
        
        // Record locations if requested
        if requestingLocationRecording {
            do {
                try recorder.logTrackPoint(location: currentLocation, gpsClient: "iOS")
            }
            catch {
                Log.e(TAG, "logTrackPoint() Error: \(error)")
            }
        }

        NotificationCenter.default.post(name: LocationUpdatedNotification.Name,
                object: self, userInfo: LocationUpdatedNotification(location: currentLocation).userInfo)

        // We don't notify map automatically (delegate), instead of that we will call manually
        // mapView.updateLocation(location). This gives us control on what GPS location is the map displaying
        // For example this class can use external GPS provider
    }

    /// This is the main method where new heading is reported.
    ///  - broadcasts new heading for potential listeners through notification center
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.lastReportedHeading = newHeading

        NotificationCenter.default.post(name: HeadingUpdatedNotification.Name,
                object: self, userInfo: HeadingUpdatedNotification(heading: newHeading).userInfo)

        // We don't notify map automatically (delegate), instead of that we will call manually
        // mapView.updateLocation(location). This gives us control on what GPS location is the map displaying
        // For example this class can use external GPS provider
    }

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        delegate?.locationManagerShouldDisplayHeadingCalibration(self) ?? false
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }
}
