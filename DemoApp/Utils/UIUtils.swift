//
//  UIUtils.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/21/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit
import AccuTerraSDK

public class UIUtils {
    
    static func getIndexFromTask(task: TaskTypes) -> Int {
        var pointer = 0
        for item in TaskBar.tasks {
            if item.value == task {
                pointer = item.key
                break
            }
        }
        return pointer
    }

    ///
    /// Converts distance in kilometers to miles
    /// - parameters:
    ///    - kilometers: value in km
    /// - returns: distance in miles
    ///
    public static func distanceKilometersToMiles(kilometers: Double) -> String {
        return String(format: "%.1f mi", kilometers * 0.621371)
    }
    
    /**
     * Returns corresponding [UIImage] for given [trackingOption].
     */
    public static func getLocationTrackingIcon(trackingOption: TrackingOption) -> UIImage {
        switch trackingOption {
        case .NONE ,.NONE_WITH_LOCATION, .NONE_WITH_GPS_LOCATION:
                return UIImage(systemName: "location.slash")!
            
        case .LOCATION:
                return UIImage(systemName: "scope")!
            
        case .DRIVING:
                return UIImage(systemName: "location.fill")!
            
        case .NONE_WITH_DRIVING:
                return UIImage(systemName: "location")!
        default:
            fatalError("The \(trackingOption) tracking option is not supported.")
        }
    }
    
    public static func loopNextElement<T>(array: [T], currentElement: T) -> T where T:Equatable {
        if array.count == 0 {
            return currentElement
        }
        var index = array.firstIndex { (item) -> Bool in
            return item == currentElement
        } ?? -1
        index = index + 1
        if (index == array.count) {
            index = 0
        }
        return array[index]
    }
}
