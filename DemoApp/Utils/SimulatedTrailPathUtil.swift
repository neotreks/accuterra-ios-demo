//
//  SimulateTrailUtil.swift
//  DemoApp
//
//  Created by Montana Grier on 11/7/22.
//  Copyright © 2022 NeoTreks. All rights reserved.
//

import Foundation

class SimulatedTrailPathUtil {
    static var isTrailPathSimulated: Bool {
        return Bundle.main.infoDictionary?["SIMULATE_TRAIL_PATH"] as? Bool ?? false
    }
}
