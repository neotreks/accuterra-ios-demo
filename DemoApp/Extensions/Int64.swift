//
//  Int64.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 26/05/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

extension Int64 {
    func humanFileSize() -> String {
        let estimateSizeInGb = Double(self) / 1024.0 / 1024.0 / 1024.0
        if estimateSizeInGb >= 1 { //GB
            return String(format: "%.1f GB", estimateSizeInGb)
        } else if estimateSizeInGb >= 0.001 { //MB
            return String(format: "%.1f MB", estimateSizeInGb * 1024)
        } else { //KB
            return String(format: "%.1f KB", estimateSizeInGb * 1024 * 1024)
        }
    }
}
