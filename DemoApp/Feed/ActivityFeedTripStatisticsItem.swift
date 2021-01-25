//
//  ActivityFeedTripStatisticsItem.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// Activity Feed Trip Statistics Item
class ActivityFeedTripStatisticsItem: BaseFeedItem<ActivityFeedEntry> {
    let info: ActivityFeedEntry
    
    init (info: ActivityFeedEntry) {
        self.info = info
        super.init(type: .ONLINE_TRIP_STATISTICS, tripUUID: info.trip.uuid, data: info)
    }
}
