//
//  ActivityFeedTripHeaderViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

class ActivityFeedTripHeaderViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var relatedTrailLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    func bindView(item: ActivityFeedTripHeaderItem) {
        guard let data = item.data else {
            return
        }
        
        // Data
        nameLabel.text =  data.trip.tripName
        locationLabel.text = data.trip.location.getLocationLabelString()
        descriptionLabel.text = data.trip.description
        
        if let trailName = data.trip.trailName {
            relatedTrailLabel.isHidden = false
            let trailNameText = "Trail: \(trailName)"
            relatedTrailLabel.text = trailNameText
        } else {
            relatedTrailLabel.isHidden = true
        }
    }
    
    static func getEstimatedHeight(item: ActivityFeedTripHeaderItem, table: UITableView) -> CGFloat {
        var estimatedHeight: CGFloat = 60
        guard let data = item.data else {
            return estimatedHeight
        }
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: table.frame.width, height: 0))
        label.numberOfLines = 0
        label.font = label.font.withSize(14)
        label.text = ""
        if let trailName = data.trip.trailName {
            label.text = "Trail: \(trailName)\n"
        }
        if let description = data.trip.description {
            label.text = "\(label.text!)\(description)"
        }
        label.sizeToFit()
        estimatedHeight += label.frame.size.height
        return estimatedHeight
    }
}
