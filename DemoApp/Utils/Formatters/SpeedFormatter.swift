//
// Created by Rudolf Kopřiva on 11/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation
import CoreLocation

class SpeedFormatter {
    static func formatSpeed(speedInMetersPerSecond: CLLocationSpeed) -> String {
        String(format: "%.1f mph", speedInMetersPerSecond * 2.23693629)
    }
}