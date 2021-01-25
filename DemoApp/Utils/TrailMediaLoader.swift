//
//  TrailMediaLoader.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 07/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import UIKit

class TrailMediaLoader : NSObject, MediaLoader {
    
    private(set) var media: TrailMedia!
    private(set) var variant: ApkMediaVariant!
    
    init(media: TrailMedia, variant: ApkMediaVariant) {
        self.media = media
        self.variant = variant
        super.init()
    }
    
    func load(callback: @escaping (MediaLoader, UIImage?) -> Void) {
        guard let url = try? ApkMediaVariantUtil.getUrlForVariant(baseUrl: media.url, mediaCategoryNumber: media.mediaCategoryNumber, variant: variant) else {
            callback(self, nil)
            return
        }
        ServiceFactory.getTrailMediaService().getMediaFile(url: url, avoidCache: false, callback: { (url) in
            callback(self, UIImage(contentsOfFile: url.path))
        }) { (error) in
            callback(self, nil)
        }
    }
}
