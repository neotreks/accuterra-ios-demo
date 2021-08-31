//
//  TripRecordingMediaCollectionViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 17/10/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

protocol TripRecordingMediaCollectionViewCellDelegate : AnyObject {
    func tripMediaDeletePressed(media: TripRecordingMedia)
    func canEditMedia(media: TripRecordingMedia) -> Bool
}

class TripRecordingMediaCollectionViewCell: UICollectionViewCell {

    static let cellIdentifier = "TripRecordingMediaCollectionViewCell"
    static let cellXibName = "TripRecordingMediaCollectionViewCell"
    

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteImageView: UIImageView!
    @IBOutlet weak var favoriteIcon: UIImageView!
    weak var delegate: TripRecordingMediaCollectionViewCellDelegate?
    private var media: TripRecordingMedia?
    private var mediaLoader: MediaLoader?

    func bindView(media: TripRecordingMedia, isPreferred: Bool = false, delegate: TripRecordingMediaCollectionViewCellDelegate?) {
        self.media = media

        if media.isLocalMedia {
            // This is case when new Media are recorded and are available locally
            // So we display it via `TripRecordingMedia.url`

            self.imageView.image = UIImage(contentsOfFile: media.url.path)
        } else {
            // This is an online Trip Editing case when given _original_ media
            // are not available locally but are present on the sever.
            // We have to display it the same way we do for `Online Trip Media`

            mediaLoader = MediaLoaderFactory.tripRecordingMediaLoader(media: media, variant: .DEFAULT)
            mediaLoader?.load(callback: { [weak self] (mediaLoader, image) in
                if let loader = self?.mediaLoader, mediaLoader.isEqual(loader: loader) {
                    self?.imageView.image = image ?? UIImage(systemName: "bolt.horizontal.circle")
                }
            })
        }

        self.delegate = delegate
        if delegate?.canEditMedia(media: media) ?? true {
            self.deleteButton.isHidden = false
            self.deleteImageView.isHidden = false
        } else {
            self.deleteButton.isHidden = true
            self.deleteImageView.isHidden = true
        }
        self.favoriteIcon.isHidden = !isPreferred
    }
    
    @IBAction func deletePressed() {
        delegate?.tripMediaDeletePressed(media: self.media!)
    }
}
