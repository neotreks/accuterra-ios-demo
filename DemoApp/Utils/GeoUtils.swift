//
//  File.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/7/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

public class GeoUtils {

    private static let DEGREES: Double = (180.0 / Double.pi)

    /// Calculates distance between two points
    ///
    /// - Parameter latA: Latitude of the A point
    /// - Parameter lonA: Longitude of the A point
    /// - Parameter latB: Latitude of the B point
    /// - Parameter lonB: Longitude of the B point
    ///
    /// - Returns: Distance between two points in meters
    static func distance(latA: Double, lonA: Double, latB: Double, lonB: Double) -> Double {
        let a1 = latA / DEGREES
        let a2 = lonA / DEGREES
        let b1 = latB / DEGREES
        let b2 = lonB / DEGREES
        let t1 =
            cos(a1) * cos(a2) * cos(
                b1
            ) * cos(b2)
        let t2 =
            cos(a1) * sin(a2) * cos(
                b1
            ) * sin(b2)
        let t3 =
            sin(a1) * sin(b1)
        let tt = acos(t1 + t2 + t3)
        return 6366000 * tt
    }
}
