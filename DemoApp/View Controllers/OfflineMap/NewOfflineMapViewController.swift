//
//  NewOfflineMapViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 18.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import MapLibre
import AccuTerraSDK

class NewOfflineMapViewController: BaseViewController {
    
    private let MAX_DOWNLOAD_SIZE_BYTES: Int64 = 1024 * 1024 * 1024 // 1 GB

    // MARK:- Outlets
    @IBOutlet weak var mapView: AccuTerraMapView!
    @IBOutlet weak var myLocationButton: UIButton!
    @IBOutlet weak var layersButton: UIButton!
    @IBOutlet weak var includeImagerySwitch: UISwitch!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var estimateLabel: UILabel!
    @IBOutlet weak var mapNameTextField: UITextField!
    @IBOutlet weak var maxControlsHeighConstraint: NSLayoutConstraint!

    // MARK:- Properties
    private let TAG = "NewOfflineMapViewController"
    
    var initLoading : Bool = true
    var mapWasLoaded : Bool = false
    
    var editOfflineMapId: String? = nil
    
    // Location tracking mode
    private var currentTracking = TrackingOption.LOCATION
    private var lastGpsTracking: TrackingOption?

    // Available tracking options
    private let trackingOptions: [TrackingOption] =
        [.LOCATION, .NONE_WITH_LOCATION]
    
    /// List of styles, the layers button cycles through them
    var styles: [URL] = [AccuTerraStyle.vectorStyleURL, ApkHereMapClass().styleURL]
    
    /// Current style Id
    var styleId = 0
    
    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotifications()
        
        if let editOfflineMapId = self.editOfflineMapId {
            tryOrShowError {
                if let offlineMap = try OfflineMapManager.shared.getOfflineMap(offlineMapId: editOfflineMapId) as? IAreaOfflineMap {
                    includeImagerySwitch.isOn = offlineMap.containsImagery
                    mapNameTextField.text = offlineMap.areaName
                }
            }
        }
        
        loadMap()
        self.mapNameTextField.autocapitalizationType = UITextAutocapitalizationType.sentences
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.title = "Pan and zoom to desired extent"
        super.viewDidAppear(animated)
    }

    // MARK:- IBActions
    @IBAction func myLocationPicked(_ sender: Any) {
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

    @IBAction func layersPressed(_ sender: Any) {
        self.layersButton.isEnabled = false
        tryOrShowError {
            try self.cycleStyle()
        }
    }
    
    @IBAction func didChangeSwitchValue() {
        refreshEstimate()
    }
    
    @IBAction func didTapDownloadButton() {
        guard mapWasLoaded else {
            return
        }
        
        let visibleRegion = mapView.visibleCoordinateBounds
        if let mapBounds = try? MapBounds(minLat: visibleRegion.sw.latitude,
                                  minLon: visibleRegion.sw.longitude,
                                  maxLat: visibleRegion.ne.latitude,
                                  maxLon: visibleRegion.ne.longitude) {
        
            let includeImagry = includeImagerySwitch.isOn
            if let size = try? OfflineMapManager.shared.estimateAreaCacheSize(
                bounds: mapBounds,
                includeImagery: includeImagry
            ) {
                // Check max size
                guard size.totalSize <= MAX_DOWNLOAD_SIZE_BYTES else {
                    showError("Download size must be less than \(MAX_DOWNLOAD_SIZE_BYTES.humanFileSize())".toError())
                    return
                }
                
                // Validate name
                guard let name = mapNameTextField.text, name.count > 0 else {
                    showError("Name is required".toError())
                    return
                }
                
                self.downloadButton.isEnabled = false
                
                func downloadInternal() {
                    OfflineMapManager.shared.downloadAreaOfflineMap(
                        bounds: mapBounds,
                        areaName: name,
                        includeImagery: includeImagry) { result in
                            switch result {
                            case .success(_):
                                // Return to OfflineMaps activity
                                self.navigationController?.popViewController(animated: true)
                            case .failure(let error):
                                self.showError(error)
                                self.downloadButton.isEnabled = true
                            }
                    }
                }
                
                // If this is edit, then delete the previous map
                if let editOfflineMapId = self.editOfflineMapId {
                    OfflineMapManager.shared.deleteOfflineMap(offlineMapId: editOfflineMapId) { error in
                        if let error = error {
                            self.showError(error)
                            self.downloadButton.isEnabled = true
                        } else {
                            downloadInternal()
                        }
                    }
                } else {
                    downloadInternal()
                }
            }
        }
    }

    // MARK:-
    func loadMap() {
        // Initialize map
        self.mapView.initialize(styleURL: styles[styleId])
        
        myLocationButton.layer.cornerRadius = 20.0
        myLocationButton.dropShadow()
        
        layersButton.layer.cornerRadius = 20.0
        layersButton.dropShadow()
        
        refreshEstimate()
    }
    
    func cycleStyle() throws {
        styleId += 1
        if styleId == styles.count {
            styleId = 0
        }
        let style = styles[styleId]
        try self.mapView.setStyle(styleURL:style)
    }
    
    private func refreshEstimate() {
        let visibleRegion = self.mapView.visibleCoordinateBounds
        if let mapBounds = try? MapBounds(minLat: visibleRegion.sw.latitude,
                                  minLon: visibleRegion.sw.longitude,
                                  maxLat: visibleRegion.ne.latitude,
                                  maxLon: visibleRegion.ne.longitude) {
        
            if let size = try? OfflineMapManager.shared.estimateAreaCacheSize(
                bounds: mapBounds,
                includeImagery: includeImagerySwitch.isOn
            ) {
                self.estimateLabel.text = "Estimated Download Size \(size.totalSize.humanFileSize())"
            }
        }
    }
    
    private func zoomToDefaultExtent() {
        if let editOfflineMapId = self.editOfflineMapId {
            tryOrShowError {
                if let offlineMap = try OfflineMapManager.shared.getOfflineMap(offlineMapId: editOfflineMapId) {
                    self.mapView.zoomToBounds(targetBounds: offlineMap.bounds)
                }
            }
        }
    }
    
    /// Set location tracking, changes icon of my location button.
    /// Triggers permission request if permission is required
    func setLocationTracking(trackingOption: TrackingOption) {
        currentTracking = trackingOption
        if trackingOption.isTrackingOption {
            lastGpsTracking = trackingOption
        }

        mapView.setTracking(mode: trackingOption)
    }
    
    /**
     * Returns the current state of the location permissions needed.
     */
    func hasLocationPermissions() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .denied:
            return false
        default:
            return true
        }
    }
}

// MARK:- AccuTerraMapViewDelegate extension
extension NewOfflineMapViewController : AccuTerraMapViewDelegate {
    
    func onMapLoadFailed(error: Error) {
        showError(error)
    }

    func onStyleChangeFailed(error: Error) {
        showError(error)
    }

    func didTapOnMap(coordinate: CLLocationCoordinate2D) {
    }
    
    func onSignificantMapBoundsChange() {
    }
    
    func onTrackingModeChanged(mode: TrackingOption) {
        let icon = UIUtils.getLocationTrackingIcon(trackingOption: mode)
        myLocationButton.setImage(icon, for: .normal)
    }
    
    func onMapLoaded() {
        // Used to zoom to user when app starts
        if self.initLoading == true && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            self.initLoading = false
        }
        self.layersButton.isHidden = false
        self.mapWasLoaded = true
        setLocationTracking(trackingOption: .LOCATION)
        self.zoomToDefaultExtent()
    }
    
    func onStyleChanged() {
        self.layersButton.isEnabled = true
    }
}

// MARK:- MLNMapViewDelegate extension
extension NewOfflineMapViewController : MLNMapViewDelegate {

    func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
        if self.initLoading == true && self.mapWasLoaded == true {
            self.initLoading = false
        }
    }
    
    func mapView(_ mapView: MLNMapView, didChange mode: MLNUserTrackingMode, animated: Bool) {
        if mode == .none {
        }
    }
    
    func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: Error) {
        showError(error)
    }
    
    func mapView(_ mapView: MLNMapView, regionDidChangeWith reason: MLNCameraChangeReason, animated: Bool) {
        refreshEstimate()
    }
}

// MARK:- Notifications extension
private extension NewOfflineMapViewController {
    private func registerNotifications() {
        // Handle keyboard show/hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            // if keyboard size is not available for some reason, dont do anything
            return
        }

        maxControlsHeighConstraint.constant = 220 + keyboardSize.height
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        maxControlsHeighConstraint.constant = 220
    }
}

// MARK:- TextField extensions
extension NewOfflineMapViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
