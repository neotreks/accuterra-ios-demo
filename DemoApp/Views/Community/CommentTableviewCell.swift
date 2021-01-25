//
//  CommentTableviewCell.swift
//  DemoApp
//
//  Created by Richard Cizovsky on 2/8/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class CommentTableviewCell: UITableViewCell {
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var commentTextLabel: UILabel!
    
    static let cellIdentifier = "CommentTableviewCell"
    static let cellXibName = "CommentTableviewCell"
    
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
