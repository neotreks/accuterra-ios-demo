//
//  BaseFeedItem.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

/// General class for activity feed items.
class BaseFeedItem<T> : ActivityFeedItem {
    let type: ActivityFeedItemType
    let tripUUID: String
    let data: T?
    var rawData: Any? {
        return data
    }

    init (type: ActivityFeedItemType, tripUUID: String, data: T?) {
        self.type = type
        self.tripUUID = tripUUID
        self.data = data
    }
}
