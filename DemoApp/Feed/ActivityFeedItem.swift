//
//  ActivityFeedItem.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

/// General interface for activity feed items.
protocol ActivityFeedItem {
    var type: ActivityFeedItemType { get }
    var tripUUID: String { get }
    var rawData: Any? { get }
}
