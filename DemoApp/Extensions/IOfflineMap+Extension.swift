//
//  IOfflineMap+Extension.swift
//  DemoApp
//
//  Created by Beniamin Kantor on 17.03.2023.
//  Copyright © 2023 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

extension IOfflineMap {
    
    var displayName: String {
        switch self.type {
        case .AREA:
            return (self as? IAreaOfflineMap)?.areaName ?? "Unnamed area."
        case .OVERLAY:
            return "Overlay map"
        case .TRAIL:
            if let trailName = (self as? ITrailOfflineMap)?.trailName {
                return "Trail \(trailName)"
            } else {
                return "Trail"
            }
        }
    }
}
