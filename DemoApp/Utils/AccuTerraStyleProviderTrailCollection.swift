//
//  AccuTerraStyleProviderTrailCollection.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 26.08.2024.
//  Copyright © 2024 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import UIKit

class AccuTerraStyleProviderTrailCollection: AccuTerraStyleProvider {
    override func getTrailDifficultyColor(sdkTechRating: SdkTechRating) -> UIColor {
        return TechRatingColorMapper.getTechRatingColor(techRatingCode: sdkTechRating.rawValue)
    }
}
