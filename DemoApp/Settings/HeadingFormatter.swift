//
// Created by Rudolf Kopřiva on 11/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation
import CoreLocation

class HeadingFormatter {
    static func formatHeading(heading: CLLocationDirection) -> String {
        String(format: "%.0f °", heading)
    }
}