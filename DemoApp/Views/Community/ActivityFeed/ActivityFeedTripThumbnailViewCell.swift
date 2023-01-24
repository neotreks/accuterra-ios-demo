//
//  ActivityFeedTripThumbnailViewCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Kingfisher

class ActivityFeedTripThumbnailViewCell: UITableViewCell {

    @IBOutlet weak var thumbnailMapView: UIImageView!
    
    func bindView(item: ActivityFeedTripThumbnailItem) {
        guard let data = item.data else {
            return
        }

        thumbnailMapView.image = nil
        
        if let mapImageDef = data.trip.mapImage {
            if let url = try? ApkMediaVariantUtil.getUrlForVariant(baseUrl: mapImageDef.url, mediaCategoryNumber: mapImageDef.mediaCategoryNumber, variant: .DEFAULT) {
                func displayThumbnailInternal(_ cachedImageUrl: URL?) {
                    executeBlockOnMainThread {
                        if let cacheUrl = cachedImageUrl {
                            self.thumbnailMapView.kf.setImage(with: cacheUrl)
                        } else {
                            self.thumbnailMapView.image = UIImage(systemName: "bolt.horizontal.circle")
                        }
                    }
                }

                ServiceFactory.getTripMediaService().getMediaFile(url: url, avoidCache: false) { result in
                    if case let .success(value) = result {
                        displayThumbnailInternal(value)
                    } else {
                        displayThumbnailInternal(nil)
                    }
                }
            }
        }
    }
}
