//
//  ActivityFeedTripUserViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

class ActivityFeedTripUserViewCell: UITableViewCell {

    @IBOutlet weak var userIconView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tripDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userIconView.layer.cornerRadius = userIconView.frame.width / 2.0
    }
    
    func bindView(item: ActivityFeedTripUserItem) {
        guard let data = item.data else {
            return
        }
        // Data
        userNameLabel.text = data.userId
        tripDateLabel.text = data.trip.tripStart.toLocalDateTimeString()
    }
}
