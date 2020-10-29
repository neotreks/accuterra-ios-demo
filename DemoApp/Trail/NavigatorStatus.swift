//
//  NavigatorStatus.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 17/07/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import CoreLocation

class NavigatorStatus {
    
    let status: NavigatorStatusType
    let location: CLLocation?
    let nextWayPoint: NextWayPoint?
    
    private init(_ status: NavigatorStatusType, _ location: CLLocation?, _ nextWayPoint: NextWayPoint?) {
        self.status = status
        self.location = location
        self.nextWayPoint = nextWayPoint
    }
    
    static func createNotReady() -> NavigatorStatus {
        return NavigatorStatus(NavigatorStatusType.NOT_READY, nil, nil)
    }
    static func createNavigating(location: CLLocation, situation: NextWayPoint) -> NavigatorStatus {
        return NavigatorStatus(NavigatorStatusType.NAVIGATING, location, situation)
    }
    static func createFinished(location: CLLocation, situation: NextWayPoint) -> NavigatorStatus {
        return NavigatorStatus(NavigatorStatusType.FINISHED, location, situation)
    }
    static func createWrongDirection(location: CLLocation) -> NavigatorStatus {
        return NavigatorStatus(NavigatorStatusType.WRONG_DIRECTION, location, nil)
    }
    static func createTrailLost(location: CLLocation) -> NavigatorStatus {
        return NavigatorStatus(NavigatorStatusType.TRAIL_LOST, location, nil)
    }
}
