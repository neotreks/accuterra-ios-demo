//
//  SdkConfigBuilder.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 08.04.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// Returns SdkConfig for Demo application
var demoAppSdkConfig: SdkConfig {
    get {
        guard let serviceUrl = Bundle.main.infoDictionary?["WS_BASE_URL"] as? String else {
            fatalError("WS_BASE_URL is missing in info.plist")
        }
        guard let accuTerraMapStyleUrl = Bundle.main.infoDictionary?["ACCUTERRA_MAP_STYLE_URL"] as? String else {
            fatalError("ACCUTERRA_MAP_STYLE_URL is missing in info.plist")
        }
        return SdkConfig(
            wsUrl: serviceUrl,
            accuterraMapStyleUrl: accuTerraMapStyleUrl,
            tripConfiguration: TripConfiguration(
                // Just to demonstrate the upload network type constraint
                uploadNetworkType: .CONNECTED,
                // Let's keep the trip recording on the device for development reasons,
                // otherwise it should be deleted
                deleteRecordingAfterUpload: false),
            trailConfiguration: TrailConfiguration(
                // Update trail DB during SDK initialization
                updateTrailDbDuringSdkInit: true,
                // Update trail User Data during SDK initialization
                updateTrailUserDataDuringSdkInit: true
            )
        )
    }
}
