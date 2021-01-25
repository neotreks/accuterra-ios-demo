//
//  TripRecordingMediaCollectionViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 17/10/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

protocol TripRecordingMediaCollectionViewCellDelegate : class {
    func tripMediaDeletePressed(media: TripRecordingMedia)
    func canEditMedia() -> Bool
}

class TripRecordingMediaCollectionViewCell: UICollectionViewCell {

    static let cellIdentifier = "TripRecordingMediaCollectionViewCell"
    static let cellXibName = "TripRecordingMediaCollectionViewCell"
    

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteImageView: UIImageView!
    weak var delegate: TripRecordingMediaCollectionViewCellDelegate?
    private var media: TripRecordingMedia?

    func bindView(media: TripRecordingMedia, delegate: TripRecordingMediaCollectionViewCellDelegate?) {
        self.media = media
        self.imageView.image = UIImage(contentsOfFile: media.uri.path)
        self.delegate = delegate
        if delegate?.canEditMedia() ?? true {
            self.deleteButton.isHidden = false
            self.deleteImageView.isHidden = false
        } else {
            self.deleteButton.isHidden = true
            self.deleteImageView.isHidden = true
        }
    }
    
    @IBAction func deletePressed() {
        delegate?.tripMediaDeletePressed(media: self.media!)
    }
}
