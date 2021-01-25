//
// Created by Rudolf Kopřiva on 11/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation

class ElevationFormatter {
    static func formatElevation(elevationInMeters: Double) -> String {
        String(format: "%.0f FT", elevationInMeters * 3.28084)
    }
}