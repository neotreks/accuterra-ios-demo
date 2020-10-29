//
//  Date.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 6/1/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

extension Date {
    func toIsoDateString() -> String {
        let df = DateFormatter()
        df.timeZone = TimeZone(abbreviation: "UTC")
        df.dateFormat = "yyyy-MM-dd"
        let date = df.string(from: self)
        return date
    }
    
    func toLocalDateString() -> String {
        let date = DateFormatter.localizedString(from: self, dateStyle: .long, timeStyle: .none)
        return date
    }
    
    func toLocalDateTimeString() -> String {
       let date = DateFormatter.localizedString(from: self, dateStyle: .long, timeStyle: .long)
       return date
    }
    
    func toUsDateString() -> String {
        let df = DateFormatter()
        df.timeZone = TimeZone(abbreviation: "UTC")
        df.dateFormat = "MM/dd/yyyy"
        let date = df.string(from: self)
        return date
    }
    
    func dateDifference(endDate: Date) -> String {
        let endDate = Date(timeInterval: 86400, since: self)
        let diffSeconds = Int(endDate.timeIntervalSince1970 - self.timeIntervalSince1970)
        let minutes = diffSeconds / 60
        let hours = diffSeconds / 3600
        return "\(hours):\(minutes):\(diffSeconds)"
    }
    
    /**
     * Format elapsed time in seconds to a string like "00:00:00" or "00:00"
     */
    func formatElapsedTime(seconds : Int64, alwaysShowHour: Bool = false) -> String {
        let h:Int = Int(seconds / 3600)
        let m:Int = Int((seconds/60) % 60)
        let s:Int = Int(seconds % 60)
        let output = h > 0 || alwaysShowHour ? String(format: "%02u:%02u:%02u", h,m,s) : String(format: "%02u:%02u", m,s)
        return output
    }
}
