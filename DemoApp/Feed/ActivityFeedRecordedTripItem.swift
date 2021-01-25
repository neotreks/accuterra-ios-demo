//
//  ActivityFeedRecordedTripItem.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// Activity Feed Local Recorded Trip Item
class ActivityFeedRecordedTripItem: BaseFeedItem<TripRecordingBasicInfo> {
    let info: TripRecordingBasicInfo
    
    init (info: TripRecordingBasicInfo) {
        self.info = info
        super.init(type: .LOCAL_RECORDED_TRIP, tripUUID: info.uuid, data: info)
    }
}
