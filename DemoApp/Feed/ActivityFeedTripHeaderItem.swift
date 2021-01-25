//
//  ActivityFeedTripHeaderItem.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// Activity Feed Trip Header Item
class ActivityFeedTripHeaderItem: BaseFeedItem<ActivityFeedEntry> {
    let info: ActivityFeedEntry
    
    init (info: ActivityFeedEntry) {
        self.info = info
        super.init(type: .ONLINE_TRIP_HEADER, tripUUID: info.trip.uuid, data: info)
    }
}
