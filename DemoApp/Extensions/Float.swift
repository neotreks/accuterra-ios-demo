//
//  Float.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 29.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import Foundation

extension Float {
    func fromMetersToInches() -> Float {
        return self * 39.37
    }
    
    func fromInchesToMeters() -> Float {
        return self / 39.37
    }
}
