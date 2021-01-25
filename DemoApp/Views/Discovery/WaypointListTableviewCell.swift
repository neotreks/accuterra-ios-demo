//
//  WaypointListTableviewCell.swift
//  DemoApp
//
//  Created by Richard Cizovsky on 2/8/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class WaypointListTableviewCell: UITableViewCell {
    @IBOutlet weak var poiListItemMillage: UILabel!
    @IBOutlet weak var poiListItemName: UILabel!
    @IBOutlet weak var poiDescriptionLabel: UILabel!
    
    static let cellIdentifier = "WaypointListTableviewCell"
    static let cellXibName = "WaypointListTableviewCell"
    
    weak var delegate: WaypointListViewDelegate?
    
    @IBAction func detailButtonPressed() {
        delegate?.didPressDetailButton(cell: self)
    }
    
    static func getEstimatedHeightInTable(table: UITableView, text: String) -> CGFloat {
        let width = table.frame.width - 90
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.text = text
        label.font = label.font.withSize(13)
        label.sizeToFit()
        return label.frame.size.height + 40
    }
}
