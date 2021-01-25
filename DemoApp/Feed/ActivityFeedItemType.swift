//
//  ActivityFeedItemType.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

/// Item type in activity feed list view
enum ActivityFeedItemType {
    case LOCAL_RECORDED_TRIP
    case ONLINE_TRIP_HEADER
    case ONLINE_TRIP_USER
    case ONLINE_TRIP_STATISTICS
    case ONLINE_TRIP_THUMBNAIL
    case ONLINE_TRIP_UGC_FOOTER
}
