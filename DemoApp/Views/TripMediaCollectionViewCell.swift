//
//  TripMediaCollectionViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 17/10/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

protocol TripMediaCollectionViewCellDelegate : class {
    func tripMediaDeletePressed(media: TripRecordingMedia)
    func canEditMedia() -> Bool
}

class TripMediaCollectionViewCell: UICollectionViewCell {

    static let cellIdentifier = "TripMediaCollectionViewCell"
    static let cellXibName = "TripMediaCollectionViewCell"
    

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    weak var delegate: TripMediaCollectionViewCellDelegate?
    private var media: TripRecordingMedia?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(media: TripRecordingMedia, delegate: TripMediaCollectionViewCellDelegate?) {
        self.media = media
        self.imageView.image = UIImage(contentsOfFile: media.uri.path)
        self.delegate = delegate
        if delegate?.canEditMedia() ?? true {
            self.deleteButton.isHidden = false
        } else {
            self.deleteButton.isHidden = true
        }
    }
    
    @IBAction func deletePressed() {
        delegate?.tripMediaDeletePressed(media: self.media!)
    }
}
