//
//  ProcessInfo.ThermalState.swift
//  DemoApp
//
//  Created by Martin Zly on 20.03.2023.
//  Copyright © 2023 NeoTreks. All rights reserved.
//

import Foundation

extension ProcessInfo.ThermalState {
    
    var name:  String {
        switch self {
        case .nominal:
            return "nominal"
        case .fair:
            return "fair"
        case .serious:
            return "serious"
        case .critical:
            return "critical"
        default:
            return "unknown."
        }
    }
    
    var description: String {
        switch self {
        case .nominal:
            return "The thermal state is within normal limits."
        case .fair:
            return "The thermal state is slightly elevated."
        case .serious:
            return "The thermal state is high."
        case .critical:
            return "The thermal state is significantly impacting the performance of the system and the device needs to cool down."
        default:
            return "The thermal state is unknown."
        }
    }
}
