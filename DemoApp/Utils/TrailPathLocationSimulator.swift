//
//  TrailPathLocationSimulator.swift
//  DemoApp
//
//  Created by Bhattacharya, Priyadarshi on 2022-05-20.
//  Copyright © 2022 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import Turf
import CoreLocation

class TrailPathLocationSimulator {
    private let trailDrive: TrailDrive
    private var nextPointIndex: Int = 0
    private var timer: Timer?
    private let reportInterval: Int = 1 //seconds
    private weak var delegate: LocationServiceDelegate?
    private let trailPoints: [CLLocationCoordinate2D]
    private let speed: Double = 14 // meters per seconds
    
    init(trailDrive: TrailDrive, delegate: LocationServiceDelegate) {
        self.trailDrive = trailDrive
        self.delegate = delegate

        let path = trailDrive.trailDrivePath
        let length = trailDrive.trailDrivePath.distance()! // meters

        let step = speed * Double(reportInterval)
        var distance: Double = 0
        var trailPoints = [CLLocationCoordinate2D]()
        while (distance < length) {
            trailPoints.append(path.coordinateFromStart(distance: distance)!)
            distance += step
        }
        trailPoints.append(path.coordinates.last!)

        self.trailPoints = trailPoints
    }
    
    deinit {
        stop()
    }
    
    func start() {
        if timer != nil {
            return
        }

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func fireTimer() {
        if nextPointIndex >= trailPoints.count {
            timer?.invalidate()
            timer = nil
            return
        }
        reportFakeLocation(pointIndex: nextPointIndex)
        nextPointIndex += 1
    }
    
    private func reportFakeLocation(pointIndex: Int) {
        let point = trailPoints[pointIndex]
        var bearing: CLLocationDirection = -1 //negative means invalid

        if pointIndex + 1 < trailPoints.count {
            let nextPoint = trailPoints[pointIndex + 1]
            bearing = calculateBearing(currentPoint: point, nextPoint: nextPoint)
        }
        
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude), altitude: 0, horizontalAccuracy: 1.0, verticalAccuracy: 0, course: bearing, speed: speed, timestamp: Date())
        
        delegate?.onLocationUpdated(location: location)
    }
    
    private func calculateBearing(currentPoint: CLLocationCoordinate2D, nextPoint: CLLocationCoordinate2D) -> Double {
        return currentPoint.direction(to: nextPoint)
    }
}
