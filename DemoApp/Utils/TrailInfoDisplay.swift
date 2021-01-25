//
//  TrailInfoDisplay.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/8/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import StarryStars

enum StarFillMode: Int {
    case full = 0
    case partial
    case none
}

public class TrailInfoDisplay {
    
    init() {
    }
    
    // Set all but description
    private static func setDisplayFieldValuesPartial(trailTitleLabel: inout UILabel, distanceLabel: inout UILabel, basicTrailInfo: TrailBasicInfo?) {
        
        if let name = basicTrailInfo?.name {
            trailTitleLabel.text = name
        }
        else {
            trailTitleLabel.text = "--"
        }
        
        if let trailDistance = basicTrailInfo?.length {
            distanceLabel.text = DistanceFormatter.formatDistance(distanceInMeters: trailDistance * 1000)
        }
        else {
            distanceLabel.text = "-- mi"
        }
    }
    
    // Description with a UILabel (Trail List)
    public static func setDisplayFieldValues(trailTitleLabel: inout UILabel, descriptionLabel: inout UILabel, distanceLabel: inout UILabel, userRatings: inout RatingView, difficultyColorBar: inout UILabel, basicTrailInfo: TrailBasicInfo?) {
        
        setDisplayFieldValuesPartial(trailTitleLabel: &trailTitleLabel, distanceLabel: &distanceLabel, basicTrailInfo: basicTrailInfo)
        
        if let description = basicTrailInfo?.highlights {
            descriptionLabel.text = description
        }
        else {
            descriptionLabel.text = "N/A"
        }
        
        if let difficulty = basicTrailInfo?.techRatingHigh {
            let techRatingColor = TechRatingColorMapper.getTechRatingColor(techRatingCode: difficulty.code)
            difficultyColorBar.backgroundColor = techRatingColor
        }
        else {
           difficultyColorBar.backgroundColor = UIColor.white
        }
    }
        
    // Description with a UITextView (Trail Info)
    public static func setDisplayFieldValues(trailTitleLabel: inout UILabel, descriptionTextView: inout UITextView, distanceLabel: inout UILabel, userRatings: inout RatingView, userRatingCountLabel: inout UILabel, userRatingValueLabel: inout UILabel, difficultyLabel: inout UILabel, basicTrailInfo: TrailBasicInfo?) {
        
        setDisplayFieldValuesPartial(trailTitleLabel: &trailTitleLabel, distanceLabel: &distanceLabel, basicTrailInfo: basicTrailInfo)
        
        if let description = basicTrailInfo?.highlights {
            descriptionTextView.attributedText = description.htmlAttributed(family: "-apple-system", size: 14, color: UIColor.Inactive!)
        }
        else {
            descriptionTextView.text = "N/A"
        }
        
        if let userRatingCount = basicTrailInfo?.userRating?.ratingCount {
            userRatingCountLabel.text = String(format: "(%d)", userRatingCount)
        }
        else {
            userRatingCountLabel.text = "*"
        }
        
        if let userRating = basicTrailInfo?.userRating?.rating {
            userRatingValueLabel.text = String(format: "%.1f", Float(userRating))
            userRatings.rating = Float(userRating)
        }
        else {
            userRatingValueLabel.text = "*"
            userRatings.rating = 0
        }
        
        if let difficulty = basicTrailInfo?.techRatingHigh {
            difficultyLabel.text = difficulty.name
        }
        else {
           difficultyLabel.text = "UNKNOWN"
        }
    }
}
