//
//  OfflineMapTableViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 18.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

protocol OfflineMapTableViewCellDelegate: AnyObject {
    func showContextMenu(offlineMapId: String)
}

class OfflineMapTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    weak var delegate: OfflineMapTableViewCellDelegate?
    
    private var offlineMapId: String?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func actionButtonPressed() {
        if let offlineMapId = self.offlineMapId {
            delegate?.showContextMenu(offlineMapId: offlineMapId)
        }
    }
    
    func bindView(offlineMap: IOfflineMap) {
        self.offlineMapId = offlineMap.offlineMapId
        
        let size = "\((offlineMap.size ?? 0).humanFileSize())"

        var name = ""
        var styles = ""
        if offlineMap.containsImagery {
            styles = "AccuTerra Outdoors - Imagery"
        } else {
            styles = "AccuTerra Outdoors"
        }

        var description = ""
        switch offlineMap.status {
            case .COMPLETE:
               description = "\(size) - \(styles)"
        case .FAILED:
                description = "Download Error"
        case .PAUSED:
                description = "Paused"
        default:
            description = "Downloading \(Int(offlineMap.progress * 100))%"
        }

        switch offlineMap.type {
        case .AREA:
            if let areaName = (offlineMap as? IAreaOfflineMap)?.areaName {
                name = areaName
            }
        case .OVERLAY:
            name = "OVERLAY"
        case .TRAIL:
            if let trailName = (offlineMap as? ITrailOfflineMap)?.trailName {
                name = "TRAIL \(trailName)"
            }
        }

        // Name and description
        nameLabel.text = name
        descriptionLabel.text = description
    }
}
