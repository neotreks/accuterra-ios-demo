//
//  OnlineTripCommentViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 07.01.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import Foundation
import UIKit
import AccuTerraSDK

class OnlineTripCommentViewCell : UITableViewCell {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    func bindView(item: TripComment) {
        // User
        userNameLabel.text = item.user.userId
        // Text
        commentLabel.text = item.text
    }
    
    static func getEstimatedHeight(item: TripComment, table: UITableView) -> CGFloat {
        var estimatedHeight: CGFloat = 30
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: table.frame.width, height: 0))
        label.numberOfLines = 0
        label.font = label.font.withSize(14)
        label.text = item.text
        label.sizeToFit()
        estimatedHeight += label.frame.size.height
        return estimatedHeight
    }
    
}
