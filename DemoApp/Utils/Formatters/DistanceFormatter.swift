//
// Created by Rudolf Kopřiva on 11/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation

class DistanceFormatter {
    static func formatDistance(distanceInMeters: Float) -> String {
        let distanceInMiles = Double(distanceInMeters) * 0.000621371

        if (distanceInMiles >= 1.0) {
            return String(format: "%.1f MI", distanceInMiles)
        } else {
            let distanceInFeet = distanceInMeters * 3.28084
            return String(format: "%.1f FT", distanceInFeet)
        }
    }
}
