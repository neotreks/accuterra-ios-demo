//
//  MediaLoader.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 07/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import UIKit

class MediaLoader : NSObject {
    
    enum MediaType {
        case Thumbnail
        case FullImage
    }
    
    private(set) var media: Media!
    private(set) var type: MediaType!
    
    init(media: Media, type: MediaType) {
        self.media = media
        self.type = type
        super.init()
    }
    
    func load(callback: @escaping (MediaLoader, UIImage?) -> Void) {
        var url: String!
        switch type {
        case .FullImage:
            url = media.url
        case .Thumbnail:
            guard let thumbnailUrl = media.thumbNailUrl else {
                callback(self, nil)
                return
            }
            url = thumbnailUrl
        default:
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
