//
//  TrailImageCollectionViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 07/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class TrailImageCollectionViewCell: UICollectionViewCell {
    
    static let cellIdentifier = "TrailImageCollectionViewCell"
    static let cellXibName = "TrailImageCollectionViewCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    
    private var mediaLoader: MediaLoader?

    func bindView(media: TrailMedia) {
        if let mediaLoader = self.mediaLoader, mediaLoader.mediaUrl() == media.url {
            return //already loaded or loading the same media
        }
        self.mediaLoader = MediaLoaderFactory.trailMediaLoader(media: media, variant: .THUMBNAIL)
        self.imageView.image = nil
        self.imageLoadingIndicator.startAnimating()
        
        mediaLoader?.load(callback: { [weak self] (mediaLoader, image) in
            if let loader = self?.mediaLoader, mediaLoader.isEqual(loader: loader) {
                self?.imageView.image = image
                self?.imageLoadingIndicator.stopAnimating()
            }
        })
    }
}
