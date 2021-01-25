//
//  TripMediaCollectionViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 17/10/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Kingfisher

protocol TripMediaCollectionViewCellDelegate : class {
    func tripMediaDeletePressed(media: TripMedia)
    func canEditMedia() -> Bool
}

class TripMediaCollectionViewCell: UICollectionViewCell {

    static let cellIdentifier = "TripMediaCollectionViewCell"
    static let cellXibName = "TripMediaCollectionViewCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteImageView: UIImageView!
    
    weak var delegate: TripMediaCollectionViewCellDelegate?
    private var mediaLoader: TripMediaLoader?
    
    func bindView(media: TripMedia, mediaVariant: ApkMediaVariant, delegate: TripMediaCollectionViewCellDelegate?) {
        imageView.image = nil
        
        mediaLoader = TripMediaLoader(media: media, variant: mediaVariant)
        mediaLoader?.load(callback: { [weak self] (loader, image) in
            if (loader as? TripMediaLoader) == self?.mediaLoader {
                self?.imageView.image = image ?? UIImage(systemName: "bolt.horizontal.circle")
            }
        })
        
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
        guard let media = self.mediaLoader?.media else {
            return
        }
        delegate?.tripMediaDeletePressed(media: media)
    }
}
