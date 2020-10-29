//
//  TripListTableViewCell.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 5/28/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import UIKit

class TripListTableViewCell: UITableViewCell {
    @IBOutlet weak var lblStartDate: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblLength: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblType: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setTrip(trip: TripRecording) {
        self.lblName.text = trip.tripInfo.name.uppercased()
        self.lblDescription.text = trip.tripInfo.description
        
        let status = trip.recordingInfo.status
        self.lblStatus.text = "\(status)"
        
        self.lblStartDate.text = trip.recordingInfo.start.toLocalDateTimeString()
        
        self.lblLength.text = "\(trip.tripStatistics.length.toMiles().round(to: 2)) mi"

        self.lblDuration.text = Date().formatElapsedTime(seconds: trip.tripStatistics.drivingTime, alwaysShowHour: true)

        self.lblType.text = trip.tripInfo.trailId == nil ? "Free Roam" : "Trail Route"
    }
}
