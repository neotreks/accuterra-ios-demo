//
//  ActivityFeedTripStatisticsViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

class ActivityFeedTripStatisticsViewCell: UITableViewCell {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    func bindView(item: ActivityFeedTripStatisticsItem) {
        guard let data = item.data else {
            return
        }
        // Data
        distanceLabel.text = DistanceFormatter.formatDistance(distanceInMeters: data.trip.length)
        durationLabel.text = DrivingTimeFormatter.formatDrivingTime(ctimeInSeconds: data.trip.drivingTime)
        
        if data.trip.trailId != nil {
            typeLabel.text = "Trail Drive"
        } else {
            typeLabel.text = "Free Roam"
        }
    }
}
