//
//  BaseDrivingViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 15/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit
import AccuTerraSDK
import Mapbox
import Reachability

class BaseDrivingViewController : LocationViewController {

    // MARK:- IBOutlets
    @IBOutlet weak var drivingModeButton: UIButton!
    @IBOutlet weak var mapView: AccuTerraMapView!
    @IBOutlet weak var layersButton: UIButton!

    // MARK:- Properties
    private var mapLoaded: Bool = false

    // Used to check if internet connection is available
    var reachability: Reachability!

    // Location tracking mode
    private(set) var currentTracking = TrackingOption.LOCATION
    private var lastGpsTracking: TrackingOption?

    // Available tracking options
    private let trackingOptions: [TrackingOption] =
            [.LOCATION, .DRIVING]

    // Current style id
    private var currentStyle = AccuTerraStyle.vectorStyleURL

    // Available online styles
    private let styles: [URL] = [
        AccuTerraStyle.vectorStyleURL,
        HEREMapsURLProtocol.styleURL]

    // Available offline styles
    private let offlineStyles: [URL] = [
        HEREMapsURLProtocol.styleURL,
        AccuTerraStyle.vectorStyleURL]

    // MARK:- Lifecycle
    deinit {
        NotificationCenter.default.removeObserver(self)
        OfflineMapManager.shared.removeProgressObserver(observer: self)
        self.reachability.stopNotifier()
    }

    override func viewDidLoad() {
        do {
            // Initialize reachability
            self.reachability = try Reachability()
            try self.reachability.startNotifier()

            // Monitor network reachability changes
            NotificationCenter.default.addObserver(forName: Notification.Name.reachabilityChanged, object: nil, queue: nil) { (notification) in
                self.onReachabilityChangedNotification(notification: notification)
            }
        } catch {
            fatalError("\(error)")
        }

        super.viewDidLoad()
        setupMap()
        OfflineMapManager.shared.addProgressObserver(observer: self)
    }

    // MARK:- IBActions
    @IBAction private func drivingModeButtonPressed() {
        onToggleLocationTrackingMode()
    }

    @IBAction func layerButtonPressed() {
        tryOrShowError {
            try onToggleMapStyle()
        }
    }

    // MARK:-

    /// Called when map style should toggle
    func onToggleMapStyle() throws {
        guard self.styles.count > 1 else {
            return
        }

        self.layersButton.isEnabled = false
        self.drivingModeButton.isEnabled = false

        self.currentStyle = UIUtils.loopNextElement(array: styles, currentElement: self.currentStyle)
        if reachability.connection == .unavailable && !offlineStyles.contains(self.currentStyle) {

            // If this style is not available offline, cycle to next

            try onToggleMapStyle()
            return
        }
        try self.mapView.setStyle(styleURL: currentStyle, styleProvider: getStyleProvider(style: currentStyle))
    }

    private func onToggleLocationTrackingMode() {
        let isMapTracking = mapView.isTrackingCameraMode
        let lastGpsTracking = self.lastGpsTracking
        if isMapTracking || lastGpsTracking == nil {
            let newTracking: TrackingOption = UIUtils.loopNextElement(
                    array: trackingOptions, currentElement: currentTracking
            )
            setLocationTracking(trackingOption: newTracking)
        } else {
            setLocationTracking(trackingOption: lastGpsTracking!)
        }
    }

    /// Called when reachability changes
    private func onReachabilityChangedNotification(notification: Notification) {
        if self.reachability.connection == .unavailable {
            // When network is not available we want to switch to offline style, but only if it's cached
            tryOrShowError {
                if let status = try OfflineMapManager.shared.getOverlayOfflineMap()?.status, status == .COMPLETE {
                    if self.mapView.isStyleLoaded {
                        if !self.offlineStyles.contains(self.currentStyle) {
                            try self.onToggleMapStyle()
                        }
                    }
                } else {
                    self.layersButton.isEnabled = false
                }
            }
        } else {
            self.layersButton.isEnabled = true
        }
    }

    /// Get the [IAccuTerraStyleProvider] to be able to customize styles
    /// of trail paths, waypoints, markers, etc.
    private func getStyleProvider(style: URL) -> IAccuTerraStyleProvider? {
        if isSatellite(style: style) {
            return AccuTerraSatelliteStyleProvider(mapStyle: style)
        } else {
            return AccuTerraStyleProvider(mapStyle: style)
        }
    }

    /// Returns true if style is aerial, so we can set better style
    private func isSatellite(style: URL) -> Bool {
        if let _ = style.absoluteString.range(of: "satellite-streets", options: .caseInsensitive) {
            return true
        } else {
            return false
        }
    }

    /// Initialize map
    func setupMap() {
        self.layersButton.isEnabled = false
        self.drivingModeButton.isEnabled = false
        self.mapView.initialize(styleURL: currentStyle, accuTerraDelegate: self, delegate: self)
    }

    func zoomToWayPoint(wayPoint: MapPoint) {
        mapView.zoomToPoint(mapLocation: wayPoint.location)
    }

    /// Set location tracking, changes icon of my location button.
    /// Triggers permission request if permission is required
    func setLocationTracking(trackingOption: TrackingOption) {
        currentTracking = trackingOption
        if trackingOption.isTrackingOption {
            lastGpsTracking = trackingOption
        }

        if (hasLocationPermissions()) {
            mapView.setTracking(mode: trackingOption)
        }
    }

    func switchToDrivingMode() {
        // the driving mode requires Location permissions
        setLocationTracking(trackingOption: .DRIVING)
    }

    func exitDrivingMode() {
        setLocationTracking(trackingOption: .NONE_WITH_GPS_LOCATION)
        drivingModeButton.isHidden = false
    }

    override func onLocationUpdated(location: CLLocation) {
        mapView.updateLocation(location: location)
    }

    override func onHeadingUpdated(heading: CLHeading) {
        mapView.updateHeading(heading: heading)
    }
}

// MARK:- MGLMapViewDelegate extension
extension BaseDrivingViewController : MGLMapViewDelegate {
}

// MARK:- AccuTerraMapViewDelegate extension
extension BaseDrivingViewController : AccuTerraMapViewDelegate {
    func onStyleChanged() {
        self.layersButton.isEnabled = true
        self.drivingModeButton.isEnabled = true
    }
    
    func didTapOnMap(coordinate: CLLocationCoordinate2D) {
        // We do not want to do anything
    }
    
    func onTrackingModeChanged(mode: TrackingOption) {
        let icon = UIUtils.getLocationTrackingIcon(trackingOption: mode)
        drivingModeButton.setImage(icon, for: .normal)
    }
    
    func onMapLoaded() {
        self.mapLoaded = true
        self.layersButton.isEnabled = true
        self.drivingModeButton.isEnabled = true
        checkLocationPermissions()
        startLocationUpdates()
    }
    
    func onSignificantMapBoundsChange() {
        // We do not want to do anything
    }
}

// MARK:- CacheProgressDelegate extension
extension BaseDrivingViewController : CacheProgressDelegate {
    func onProgressChanged(offlineMap: IOfflineMap) {
        // We do not want to do anything
    }
    
    func onError(error: [OfflineResourceError], offlineMap: IOfflineMap) {
        
        // When download fails the onError is called first followed by onComplete
        
        let message = error.map ({ (resourceError) -> String in
            return "\(resourceError.offlineResource.getResourceTypeName()) failed \(resourceError.error)"
        }).joined(separator: "\n")
        
        showError(message.toError())
    }
    
    func onComplete(offlineMap: IOfflineMap) {
        // We do not want to do anything here
    }
}
