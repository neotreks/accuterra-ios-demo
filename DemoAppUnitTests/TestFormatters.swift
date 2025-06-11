//
//  TestFormatters.swift
//  DemoAppUnitTests
//
//  Created by Rudolf Kopřiva on 27.01.2023.
//  Copyright © 2023 NeoTreks. All rights reserved.
//

import Foundation
import XCTest

class TestFormatters: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func testSpeedFormatter() throws {
        let mph = SpeedFormatter.formatSpeed(speedInMetersPerSecond: 1)
        XCTAssertEqual(mph, "2.2 mph")
    }

    func testLatLonFormatter() throws {
        let lat = LatLonFormatter.formatLatLon(value: 11.123459)
        XCTAssertEqual(lat, "11.12346")
    }

    func testHeadingFormatter() throws {
        let heading = HeadingFormatter.formatHeading(heading: 11.623459)
        XCTAssertEqual(heading, "12 °")
    }

    func testElevationFormatter() throws {
        let elevation = ElevationFormatter.formatElevation(elevationInMeters: 110)
        XCTAssertEqual(elevation, "361 FT")
    }

    func testDrivingTimeFormatter() throws {
        let drivingTime = DrivingTimeFormatter.formatDrivingTime(ctimeInSeconds: 3700)
        XCTAssertEqual(drivingTime, "01:01:40")
    }

    func testDistanceFormatter() throws {
        let distanceFt = DistanceFormatter.formatDistance(distanceInMeters: 110)
        XCTAssertEqual(distanceFt, "360.9 FT")

        let distanceMi = DistanceFormatter.formatDistance(distanceInMeters: 11000)
        XCTAssertEqual(distanceMi, "6.8 MI")
    }
    
}
