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
var demoAppSdkConfig: ApkSdkConfig = {
    guard let WS_BASE_URL = Bundle.main.infoDictionary?["WS_BASE_URL"] as? String else {
        fatalError("WS_BASE_URL is missing in info.plist")
    }
    guard let WS_AUTH_URL = Bundle.main.infoDictionary?["WS_AUTH_URL"] as? String else {
        fatalError("WS_AUTH_URL is missing in info.plist")
    }
    let sdkEndpointConfig = SdkEndpointConfig(wsUrl: WS_BASE_URL, wsAuthUrl: WS_AUTH_URL)
    return ApkSdkConfig(
        sdkEndpointConfig: sdkEndpointConfig,
        mapConfig: MapConfig(
            // providing nil value will load map token and style url from backend
            accuTerraMapConfig: nil,
            // custom imagery style
            imageryMapConfig: ImageryMapConfig(styleURL: ApkHereMapClass().styleURL)),
        tripConfiguration: TripConfiguration(
            // Just to demonstrate the upload network type constraint
            uploadNetworkType: .CONNECTED,
            // Let's keep the trip recording on the device for development reasons,
            // otherwise it should be deleted
            deleteRecordingAfterUpload: false,
            attachmentSplitConfig: TripAttachmentSplitConfig(attachmentSplitSizeLimit: 2.0, attachmentSplitChunkSize: 1.0)),
        trailConfiguration: TrailConfiguration(
            // Increases launch time
            trailFeatureCacheMode: .CACHE_TRAILS_WHEN_ACCESSED,
            // Update trail DB during SDK initialization
            updateTrailDbDuringSdkInit: false,
            // Update trail User Data during SDK initialization
            updateTrailUserDataDuringSdkInit: false,
            // Update trail Dynamic Data during SDK initialization (ratings, reported closed dates, etc.)
            updateTrailDynamicDataDuringSdkInit: false
        ),
        
        mapRequestInterceptor: ApkHereMapClass()
    )
}()
