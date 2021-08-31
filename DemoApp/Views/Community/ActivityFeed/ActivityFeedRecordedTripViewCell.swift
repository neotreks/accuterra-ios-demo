//
//  ActivityFeedRecordedTripViewCell.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 5/28/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import UIKit

class ActivityFeedRecordedTripViewCell: UITableViewCell {
    @IBOutlet weak var lblStartDate: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var lblDescription: UILabel!

    func bindView(recording: TripRecordingBasicInfo) {
        self.lblStartDate.text = recording.startDate.toLocalDateTimeString(dateStyle: .medium, timeStyle: .none)
        self.lblName.text = recording.name.uppercased()
        self.lblStatus.text = recording.status.name
        self.lblDescription.text = recording.description
        
        if (recording.status == .QUEUED || recording.status == .UPLOADED) {
            lblStatus.textColor = UIColor.Primary
        } else if recording.status == .PROCESSED {
            lblStatus.textColor = UIColor.AppGreen
        }
        else {
            lblStatus.textColor = UIColor.Accent
        }
    }
    
    static func getEstimatedHeight(recording: TripRecordingBasicInfo, table: UITableView) -> CGFloat {
        var estimatedHeight: CGFloat = 60
        guard let desc = recording.description else {
            return estimatedHeight
        }
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: table.frame.width - 130, height: 0))
        label.numberOfLines = 0
        label.font = label.font.withSize(13)
        label.text = desc
        
        label.sizeToFit()
        estimatedHeight += label.frame.size.height
        return estimatedHeight
    }
}
