//
// Created by Rudolf Kopřiva on 28.11.2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

final class ApkMediaUtil {
    static func updatePositions(allMedia: [TripRecordingMedia]) -> [TripRecordingMedia] {
        var position = 1
        var ordered = [TripRecordingMedia]()
        for media in allMedia {
            // Set the optional position value
            position += 1
            ordered.append(media.copy(position: position))
        }
        return ordered
    }
}