//
//  UploadStatusTableViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 30.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class UploadStatusTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func bindWithRequest(request: UploadRequest) {
        self.typeLabel.text = request.dataType.name
        self.priorityLabel.text = request.priority.name
        self.statusLabel.text = request.uploadDate == nil ? "QUEUED" : "UPLOADED"
        self.statusLabel.textColor = request.uploadDate == nil ? UIColor.Accent : UIColor.Primary
        self.descriptionLabel.text = request.fullInfo
    }
}
