//
//  PoiTagCollectionViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 28.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class PoiTagCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var name: UILabel!
    
    func bindView(tag: ITag, selected: Bool) {
        self.name.text = " \(tag.name) "
        self.isSelected = selected
        
        self.name.backgroundColor = selected ? UIColor.Active : UIColor.gray
    }
}
