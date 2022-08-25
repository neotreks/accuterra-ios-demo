//
//  BaseTripRecordingViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 11/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit
import AccuTerraSDK
import CoreLocation

class BaseTripRecordingViewController : BaseDrivingViewController {

    // MARK:- Outlets
    @IBOutlet weak var buttonStart: UIButton!
    @IBOutlet weak var buttonFinish: UIButton!
    @IBOutlet weak var buttonResume: UIButton!
    @IBOutlet weak var buttonStop: UIButton!
    @IBOutlet weak var buttonAddPoi: UIButton!
    @IBOutlet weak var lblSpeed: UILabel!
    @IBOutlet weak var lblElevation: UILabel!
    @IBOutlet weak var lblHeading: UILabel!
    @IBOutlet weak var lblLat: UILabel!
    @IBOutlet weak var lblLong: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblLength: UILabel!

    // MARK:- Properties
    var tripStatistics: TripStatistics?
    private var tripService: ITripRecordingService?
    private let TAG = "BaseTripRecordingViewController"
    
    var tripUuid: String?
    var trailId: Int64?
    
    private var _tripRecorder: ITripRecorder!
    
    var tripRecorder: ITripRecorder {
        if _tripRecorder == nil {
            _tripRecorder = try! ServiceFactory.getTripRecorder()
            tripUuid = try! _tripRecorder.getActiveTripRecording()?.tripInfo.uuid
        }
        return _tripRecorder!
    }
    
    var buttonStartBgColor: UIColor = .clear
    var buttonStartBgRedColor: UIColor = .rgb(red: 192, green: 57, blue: 43)

    var lastLocation: CLLocation?

    var isTripLayersManagerLoaded: Bool = false
    
    /// Provide custom trip recording data to be stored with the trip recording
    func getExtProperties() -> [ExtProperties]? {
        return nil
    }
    
    /// Provide [TelemetryModel] only if the telemetry will be recorded
    func getTelemetryModel() -> TelemetryModel? {
        return nil
    }

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonAddPoi.isHidden = true
        // Initialize trip service object
        self.tripService = ServiceFactory.getTripRecordingService()
    }

    deinit {
        // Example of trying to flush recorder's buffer to persist in-memory data.
        try? tripRecorder.flushTripRecordingBuffer()

        if let currentStatus = (try? tripRecorder.getActiveTripRecording()?.recordingInfo.status),
           currentStatus != TripRecordingStatus.RECORDING {
            stopLocationUpdates()
        }
    }

    func setStartMode() {
        lblDuration.isHidden = true
        lblLength.isHidden = true
        buttonStart.isHidden = false
        buttonStop.isHidden = true
        buttonResume.isHidden = true
        buttonFinish.isHidden = true
        buttonAddPoi.isHidden = true
    }

    func setRecordingMode() {
        lblDuration.isHidden = false
        lblLength.isHidden = false
        buttonStart.isHidden = true
        buttonStop.isHidden = false
        buttonResume.isHidden = true
        buttonFinish.isHidden = true
        buttonAddPoi.isHidden = false
    }

    func setPausedMode() {
        lblDuration.isHidden = true
        lblLength.isHidden = true
        buttonStart.isHidden = true
        buttonStop.isHidden = true
        buttonResume.isHidden = false
        buttonFinish.isHidden = false
        buttonAddPoi.isHidden = false
    }

    // MARK:- IBActions

    @IBAction func onAddPoiClicked(_ sender: Any) {
        guard let poiLocation = lastLocation else {
            return
        }
        guard tripUuid != nil else {
            return
        }

        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "TripPoiVC") as? TripPoiViewController {
            do {
                try vc.createNewWithLocation(location: poiLocation)
            } catch {
                showError(error)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func onRecordingStartClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Start Recording", message: "Do you really want to start trip recording?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in

            let activeTrip = try? self.tripRecorder.getActiveTripRecording()

            do {
                try self.mapView.tripLayersManager.setTripRecorder(tripRecorder: self.tripRecorder)
                if let activeTripStatus = activeTrip?.recordingInfo.status {
                    throw "Cannot start trip when there is another trip in \(activeTripStatus.name) state.".toError()
                }
                let tripName = "Trip \(Date().toLocalDateString())" // Default name
                let vehicleId = "test_vehicle" // TODO: Load vehicle ID
                let result: AccuTerraSDK.Result<TripStartResult> =
                    try self.tripRecorder.startTripRecording(
                        name: tripName, trailId: self.trailId,
                        vehicleId: vehicleId, extProperties: self.getExtProperties(), telemetryModel: self.getTelemetryModel())

                if result.isFailure {
                    self.showError(result.error ?? "Could not start trip recording.".toError())
                } else {
                    if result.value?.startType == TripStartResultType.OK_NEW_STARTED {
                        self.tripUuid = result.value?.tripUuid
                    }
                    Log.d(self.TAG, "Trip UUID: \(String(describing: self.tripUuid))")

                    self.updateRecordingButtons()
                    // Start recording
                    self.startLocationRecording()
                }
            } catch {
                Log.e(self.TAG, "startTrip() Error: \(error)")
                self.showError(error)
            }
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        self.present(alert, animated: true)
    }

    @IBAction func onRecordingFinishClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Finish Recording", message: "Do you really want to finish trip recording?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            do {
                guard let uuid = try self.tripRecorder.getActiveTripRecording()?.tripInfo.uuid else {
                    throw "No trip UUID available.".toError()
                }
                self.stopLocationRecording()
                try self.tripRecorder.finishTripRecording()

                self.openSaveTripView(tripUuid: uuid) {
                    do {
                        try self.mapView.tripLayersManager.setTripRecorder(tripRecorder: nil)
                    } catch {
                        self.showError(error)
                    }
                    self.updateRecordingButtons()
                    self.tripUuid = nil
                    self.navigationController?.popToRootViewController(animated: false)
                }
            } catch let error as InvalidTripGeometryError {
                Log.e(self.TAG, "finishTrip() Error: \(error)")
                self.showError(error)
            } catch {
                Log.e(self.TAG, "finishTrip() Error: \(error)")
                self.showError(error)
            }
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        self.present(alert, animated: true)
    }

    @IBAction func onRecordingResumeClicked(_ sender: Any) {
        do {
            let activeTrip = try tripRecorder.getActiveTripRecording()

            // From Paused to Recording
            if activeTrip?.recordingInfo.status == TripRecordingStatus.PAUSED {
                stopLocationRecording()
                try tripRecorder.resumeTripRecording()
                // Start recording
                startLocationRecording()
            } else {
                throw "Cannot resume trip which is in a \(activeTrip?.recordingInfo.status.name ?? "unknown") state.".toError()
            }
        } catch {
            Log.e(TAG, ("finishTrip() Error: \(error)"))
            showError(error)
        }
        // Update the UI
        updateRecordingButtons()
    }

    @IBAction func onRecordPauseClicked(_ sender: Any) {
        do {
            let activeTrip = try tripRecorder.getActiveTripRecording()
            // From Recording to Paused
            if activeTrip?.recordingInfo.status == TripRecordingStatus.RECORDING {
                try tripRecorder.pauseTripRecording()
                stopLocationRecording()
                self.setPausedMode()
            } else {
                throw "Cannot pause trip which is in a \(activeTrip?.recordingInfo.status.name ?? "unknown") state.".toError()
            }
        }
        catch {
            Log.e(TAG, "finishTrip() Error: \(error)")
            showError(error)
        }
        // Update the UI
        updateRecordingButtons()
    }

    // MARK:-
    override func onLocationUpdated(location: CLLocation) {
        super.onLocationUpdated(location: location)
        updateRecordingUI(location: location)
        setLastLocation(location: location)
    }

    /// We use this just to:
    /// - update the map position
    ///  - trigger getting new statistics
    ///
    /// The location recording is done inside of the [trip.location.LocationService]
    func setLastLocation(location: CLLocation?) {
        lastLocation = location

        if self.tripUuid != nil && location != nil {
            tripStatistics = tripRecorder.getTripStatistics()
            updateStatistics(distance: tripStatistics?.length, drivingTime: tripStatistics?.drivingTime)
        }
    }

    override func onHeadingUpdated(heading: CLHeading) {
        super.onHeadingUpdated(heading: heading)
        updateRecordingUI(heading: heading)
    }
    
    func setupRecordingAfterOnAccuTerraMapViewReady() throws {
        try addTripLayers()
        updateRecordingButtons()
    }

    func updateRecordingButtons() {
        let activeTrip = try? tripRecorder.getActiveTripRecording()
        if let status = activeTrip?.recordingInfo.status {
            switch status {
            case .RECORDING:
                setRecordingMode()
            case .PAUSED:
                setPausedMode()
            default:
                setStartMode()
            }
        } else {
            setStartMode()
        }
    }
    
    func addTripLayers() throws {
        let tripLayersManager = mapView.tripLayersManager
        try tripLayersManager.addStandardTripLayers()
        isTripLayersManagerLoaded = true
        if tripRecorder.hasActiveTripRecording() {
            try tripLayersManager.setTripRecorder(tripRecorder: tripRecorder)
        }
    }

    func updateStatistics(distance: Float?, drivingTime: Int?) {
        if let distance = distance {
            lblLength.text = DistanceFormatter.formatDistance(distanceInMeters: distance)
        } else {
            lblLength.text = "N/A"
        }

        if let drivingTime = drivingTime {
            lblDuration.text = DrivingTimeFormatter.formatDrivingTime(ctimeInSeconds: drivingTime)
        } else {
            lblDuration.text = "N/A"
        }
    }

    func onEditPoiClicked(poiUuid: String) throws {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "TripPoiVC") as? TripPoiViewController {
            try vc.loadSaved(poiUuid: poiUuid)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func openSaveTripView(tripUuid: String, completion: (() -> Void)?) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "SaveTripVC") as? SaveTripViewController {
            vc.tripUuid = tripUuid
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: completion)
        }
    }
    
    func updateRecordingUI(location: CLLocation) {
        // Reset labels
        lblSpeed.text = "0 mph"
        lblElevation.text = "0 ft"
        lblHeading.text = "0º"
        lblLat.text = "0.0"
        lblLong.text = "0.0"
        
        // Update with values, if there are
        lblSpeed.text = SpeedFormatter.formatSpeed(speedInMetersPerSecond: location.speed)
        lblElevation.text = ElevationFormatter.formatElevation(elevationInMeters: location.altitude)
        lblHeading.text = HeadingFormatter.formatHeading(heading: location.course)
        lblLat.text = LatLonFormatter.formatLatLon(value: location.coordinate.latitude)
        lblLong.text = LatLonFormatter.formatLatLon(value: location.coordinate.longitude)
    }
    
    func updateRecordingUI(heading: CLHeading) {
        // Reset label
        lblHeading.text = "0º"
        
        // Update with value, if there is
        lblHeading.text = HeadingFormatter.formatHeading(heading: heading.trueHeading)
    }

    override func didTapOnMap(coordinate: CLLocationCoordinate2D) {
        guard self.isTripLayersManagerLoaded else {
            return
        }

        do {
            if try searchTripPois(coordinate: coordinate) {
                try self.mapView.tripLayersManager.highlightPOI(poiId: nil)
            }
        } catch {
            showError(error)
        }
    }

    func searchTripPois(coordinate: CLLocationCoordinate2D) throws -> Bool {
        let query = TripPoisQuery(
                tripLayersManager: mapView.tripLayersManager,
                layers: Set(TripPoiLayerType.allValues),
                coordinate: coordinate,
                distanceTolerance: 2.0)

        if let tripPoi = query.execute().tripPois.first, let poiId = tripPoi.poiIds.first {
            try handleTripPoiMapClick(tripId: tripPoi.tripId , poiId: poiId)
            return true
        } else {
            return false
        }
    }

    func handleTripPoiMapClick(tripId: String, poiId: String) throws {
        loadAndShowPoiInfo(tripUuid: tripId, poiId: poiId)
        try self.mapView.tripLayersManager.highlightPOI(poiId: poiId)
    }

    func loadAndShowPoiInfo(tripUuid: String, poiId: String) {
        let service = ServiceFactory.getTripRecordingService()

        do {
            guard try service.getTripRecordingByUUID(uuid: tripUuid) != nil else {
                throw "Trip #\(tripUuid) not found.".toError()
            }
            guard let poi = try service.getTripRecordingPoiByUuid(uuid: poiId) else {
                throw "No POI \(poiId) found for trip #\(tripUuid).".toError()
            }
            
            AlertUtils.showPrompt(viewController: self, title: "\(poi.name)", message: "Edit POI?") {
                do {
                    try self.onEditPoiClicked(poiUuid: poiId)
                } catch {
                    self.showError(error)
                }
            } cancelHandler: {
            }
        } catch {
            Log.e(TAG, error)
        }
    }
}
