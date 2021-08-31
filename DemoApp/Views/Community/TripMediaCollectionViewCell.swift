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

protocol TripMediaCollectionViewCellDelegate : AnyObject {
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
    private var mediaLoader: MediaLoader?
    private var media: TripMedia?
    
    func bindView(media: TripMedia, mediaVariant: ApkMediaVariant, delegate: TripMediaCollectionViewCellDelegate?) {
        imageView.image = nil
        self.media = media
        
        mediaLoader = MediaLoaderFactory.tripMediaLoader(media: media, variant: mediaVariant) 
        mediaLoader?.load(callback: { [weak self] (mediaLoader, image) in
            if let loader = self?.mediaLoader, mediaLoader.isEqual(loader: loader) {
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
        guard let media = self.media else {
            return
        }
        delegate?.tripMediaDeletePressed(media: media)
    }
}
