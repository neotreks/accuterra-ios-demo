//
// Created by Rudolf Kopřiva on 11/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation

class DrivingTimeFormatter {
    static func formatDrivingTime(ctimeInSeconds: Int64) -> String {
        ElapsedTime(timeInterval: Double(ctimeInSeconds)).formatted
    }
}

struct ElapsedTime {
    let hours: Int
    let minutes: Int
    let seconds: Int

    init(timeInterval: TimeInterval) {
        let validInterval = max(0.0, timeInterval)
        hours = Int(validInterval) / 3600
        minutes = Int(validInterval) / 60 % 60
        seconds = Int(validInterval) % 60
    }

    public var formatted: String {
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}