//
//  TripLocationInfo.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// Extensions related to Trip
extension TripLocationInfo {
    func getLocationLabelString() -> String {
        let firstPart = nearestTownName ?? countyName ?? districtName
        let secondPart = stateCode ?? countryIso3Code
        
        if (firstPart == nil && secondPart == nil) {
            return "n/a"
        }
        if (firstPart?.isEmpty ?? true) && !(secondPart?.isEmpty ?? true) {
            return secondPart!
        } else if !(firstPart?.isEmpty ?? true) && (secondPart?.isEmpty ?? true) {
            return firstPart!
        } else {
            return "\(firstPart!), \(secondPart!)"
        }
    }
}
