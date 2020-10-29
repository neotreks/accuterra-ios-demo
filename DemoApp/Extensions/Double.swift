//
//  Double.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 6/2/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

extension Double {
    
    /// Round to a number of decimal cases
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Convert speed from m/s to mph
    func toMilesPerHour() -> Double {
        return self * 2.236936
    }
    
    /// Convert meters to feet
    func toFeet() -> Double {
        return self * 3.28084
    }
    
    /// Convert meters to miles
    func toMiles() -> Double {
        return self * 0.0006213712
    }
}
