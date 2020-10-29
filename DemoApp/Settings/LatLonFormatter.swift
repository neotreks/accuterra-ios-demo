//
// Created by Rudolf Kopřiva on 11/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation

class LatLonFormatter {
    static func formatLatLon(value: Double) -> String {
        "\(value.round(to: 5))"
    }
}