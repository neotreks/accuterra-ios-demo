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
    
    private var mediaLoader: TrailMediaLoader?

    func bindView(media: TrailMedia) {
        if let currentMedia = self.mediaLoader?.media, currentMedia.url == media.url {
            return //already loaded or loading the same media
        }
        self.mediaLoader = TrailMediaLoader(media: media, variant: .THUMBNAIL)
        self.imageView.image = nil
        self.imageLoadingIndicator.startAnimating()
        
        mediaLoader?.load(callback: { [weak self] (mediaLoader, image) in
            if ((mediaLoader as? TrailMediaLoader) == self?.mediaLoader) {
                self?.imageView.image = image
                self?.imageLoadingIndicator.stopAnimating()
            }
        })
    }
}
