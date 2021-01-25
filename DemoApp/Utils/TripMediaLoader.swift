//
//  TripMediaLoader.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 07/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import UIKit

class TripMediaLoader : NSObject, MediaLoader {
    
    private(set) var media: TripMedia!
    private(set) var variant: ApkMediaVariant!
    
    init(media: TripMedia, variant: ApkMediaVariant) {
        self.media = media
        self.variant = variant
        super.init()
    }
    
    func load(callback: @escaping (MediaLoader, UIImage?) -> Void) {
        guard let url = try? ApkMediaVariantUtil.getUrlForVariant(baseUrl: media.url, mediaCategoryNumber: media.mediaCategoryNumber, variant: variant) else {
            callback(self, nil)
            return
        }
        ServiceFactory.getTripMediaService().getMediaFile(url: url, avoidCache: false) { (result) in
            executeBlockOnMainThread {
                if let cachedImage = result.value, result.isSuccess {
                    callback(self, UIImage(contentsOfFile: cachedImage.path))
                } else {
                    callback(self, nil)
                }
            }
        }
    }
}
