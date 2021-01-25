//
//  ActivityFeedTripUgcFooterItem.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// Activity Feed Trip Statistics Item
class ActivityFeedTripUgcFooterItem: BaseFeedItem<ActivityFeedEntry> {
    init (data: ActivityFeedEntry) {
        super.init(type: .ONLINE_TRIP_UGC_FOOTER, tripUUID: data.trip.uuid, data: data)
    }
}
