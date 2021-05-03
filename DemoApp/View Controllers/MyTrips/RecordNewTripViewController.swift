//
//  RecordNewTripViewController.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 6/1/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Mapbox
import CoreLocation

class RecordNewTripViewController: BaseTripRecordingViewController {
    
    private var demoTelemetryModel: TelemetryModel? = nil
    private var demoTelemetryType: TelemetryRecordType? = nil
    private var telemetryTimer: Timer? = nil
    private let TAG = "RecordNewTripViewController"

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Trip Recording"
        
        let item = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close))

        self.navigationItem.leftBarButtonItem = item
        
        demoTelemetryModel = try? buildTelemetryModel()
        demoTelemetryType = demoTelemetryModel?.recordTypes.first
        
        tripRecorder.addObserver(observer: self)
        
        setupMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tripRecorder.removeObserver(observer: self)
    }
    
    deinit {
        // Set screen lock back to normal
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK:- Actions
    @objc func close() {
        guard !tripRecorder.hasActiveTripRecording() else {
            showError("Cannot exit while recording a trip".toError())
            return
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func getTelemetryModel() -> TelemetryModel? {
        return demoTelemetryModel
    }
    
    private func buildTelemetryModel() throws -> TelemetryModel {
        let telemetryTypeName = "locations"
        let builder = TelemetryModelBuilder.create(name: "test_telemetry", defaultNamespace: "neo", version: 0)
        try builder.addRecordType(typeName: telemetryTypeName)
            .addDoubleField(name: "lat", required: true)
            .addDoubleField(name: "lon", required: true)
            .addDoubleField(name: "alt", required: false)
        
        return try builder.build()
    }
}

// MARK:- Map extension
extension RecordNewTripViewController {
    override func onMapLoaded() {
        super.onMapLoaded()
        do {
            try setupRecordingAfterOnAccuTerraMapViewReady()
        } catch {
            showError(error)
        }
        setLocationTracking(trackingOption: .LOCATION)
    }
}

extension RecordNewTripViewController: TripRecorderDelegate {
    func onLocationAdded(location: CLLocation) {
        // nothing to do
    }
    
    func onPoiAdded(tripPoi: TripRecordingPoi) {
        // nothing to do
    }
    
    func onPoiUpdated(tripPoi: TripRecordingPoi) {
        // nothing to do
    }
    
    func onPoiDeleted(poiUuid: String) {
        // nothing to do
    }
    
    func onRecentLocationBufferChanged(newLocation: CLLocation, bufferFlushed: Bool) {
        // nothing to do
    }
    
    func onStatusChanged(status: TripRecorderStatus) {
        switch status {
        case .RECORDING:
            telemetryTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                DispatchQueue.global().async {
                    do {
                        // We log only when there is an active recording
                        guard let type = self.demoTelemetryType, self.tripRecorder.hasActiveTripRecording() else {
                            return
                        }
                        
                        var values: [String:Any]!
                        for _ in 1...5 {
                            values = try self.buildRandomTelemetryValues(recordType: type)
                            try self.tripRecorder.logTelemetry(recordType: type, values: values)
                        }
                    } catch {
                        Log.e(self.TAG, "Error while recording telmetry because of: \(error.localizedDescription)")
                    }
                }
            })
        default:
            telemetryTimer?.invalidate()
            telemetryTimer = nil
        }
    }
    
    private func buildRandomTelemetryValues(recordType: TelemetryRecordType) throws -> [String: Any] {
        let builder = TelemetryValuesBuilder.create(recordType: recordType, timestamp: Date().millisecondsSince1970)
            .put(fieldName: "lat", value: Double.random(in: -90.0...90.0))
            .put(fieldName: "lon", value: Double.random(in: -180.0...180.0))
            .put(fieldName: "alt", value: Double.random(in:  0.0...2000.0))
        
        return builder.build()
    }
}
