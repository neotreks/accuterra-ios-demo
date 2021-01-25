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

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Trip Recording"
        
        self.navigationController?.navigationBar.barTintColor = UIColor.DrivingNavigationBarColor
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        let item = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close))

        self.navigationItem.leftBarButtonItem = item
        
        setupMap()
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
