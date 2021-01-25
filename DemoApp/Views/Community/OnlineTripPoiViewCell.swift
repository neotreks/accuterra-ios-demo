//
//  OnlineTripPoiViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 09.01.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class OnlineTripPoiViewCell: UITableViewCell {

    @IBOutlet weak var poiTypeLabel: UILabel!
    @IBOutlet weak var poiNameLabel: UILabel!
    @IBOutlet weak var poiDescriptionLabel: UILabel!
    
    func bindView(tripPoint: TripPoint) {
        self.poiTypeLabel.text = tripPoint.pointType.code.uppercased()
        self.poiNameLabel.text = tripPoint.name
        self.poiDescriptionLabel.text = tripPoint.description
    }

    static func getEstimatedHeight(tripPoint: TripPoint, table: UITableView) -> CGFloat {
        var estimatedHeight: CGFloat = 40
        guard let descriptionText = (tripPoint.description ?? tripPoint.descriptionShort), descriptionText.count > 0 else {
            return 50
        }
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: table.frame.width, height: 0))
        label.numberOfLines = 0
        label.font = label.font.withSize(13)
        label.text = descriptionText
        label.sizeToFit()
        estimatedHeight += label.frame.size.height
        return estimatedHeight
    }
    
}
