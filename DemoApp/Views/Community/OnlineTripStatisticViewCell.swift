//
//  OnlineTripStatisticViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 09.01.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit

class OnlineTripStatisticViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    func bindView(name: String, value: String) {
        self.nameLabel.text = name
        self.valueLabel.text = value
    }

}
