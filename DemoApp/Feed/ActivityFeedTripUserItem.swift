//
//  ActivityFeedTripUserItem.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// Activity Feed Trip Statistics Item
class ActivityFeedTripUserItem: BaseFeedItem<ActivityFeedEntry> {
    init (data: ActivityFeedEntry) {
        super.init(type: .ONLINE_TRIP_USER, tripUUID: data.trip.uuid, data: data)
    }
}
