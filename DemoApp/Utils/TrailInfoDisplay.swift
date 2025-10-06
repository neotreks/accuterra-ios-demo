//
//  TrailInfoDisplay.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/8/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

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
        
        if let trailDistance = basicTrailInfo?.statistics.length {
            distanceLabel.text = DistanceFormatter.formatDistance(distanceInMeters: trailDistance)
        }
        else {
            distanceLabel.text = "-- mi"
        }
    }
    
    // Description with a UILabel (Trail List)
    public static func setDisplayFieldValues(trailTitleLabel: inout UILabel, descriptionLabel: inout UILabel, distanceLabel: inout UILabel, timeLabel: inout UILabel, elevationLabel: inout UILabel, userRatings: inout RatingView, difficultyColorBar: inout UILabel, difficultyLabel: inout UILabel, difficultyView: inout UIView, bookmarkButton: UIButton, basicTrailInfo: TrailBasicInfo?) {

        setDisplayFieldValuesPartial(trailTitleLabel: &trailTitleLabel, distanceLabel: &distanceLabel, basicTrailInfo: basicTrailInfo)

        if let elevation = basicTrailInfo?.statistics.highestElevation {
            elevationLabel.text = ElevationFormatter.formatElevation(elevationInMeters: Double(elevation))
        }
        else {
            elevationLabel.text = "-- FT"
        }

        if let minTime = basicTrailInfo?.statistics.estimatedDriveTimeMin, let avgTime = basicTrailInfo?.statistics.estimatedDurationAvg {
            timeLabel.text = DrivingTimeFormatter.formatEstimatedDrivingTimeRange(minTimeInSeconds: minTime, avgTimeInSeconds: avgTime)
        } else {
            if let minTime = basicTrailInfo?.statistics.estimatedDriveTimeMin {
                timeLabel.text = DrivingTimeFormatter.formatEstimatedDrivingTime(ctimeInSeconds: minTime)
            } else if let avgTime = basicTrailInfo?.statistics.estimatedDurationAvg {
                timeLabel.text = DrivingTimeFormatter.formatEstimatedDrivingTime(ctimeInSeconds: avgTime)
            } else {
                timeLabel.text = "N/A"
            }
        }

        if let nearestTown = basicTrailInfo?.locationInfo.nearestTownName {
            descriptionLabel.text = nearestTown
        } else if let description = basicTrailInfo?.highlights {
            descriptionLabel.text = description
        } else {
            descriptionLabel.text = ""
        }

        if let difficulty = basicTrailInfo?.techRatingHigh {
            let techRatingColor = TechRatingColorMapper.getTechRatingColor(techRatingCode: difficulty.code)
            difficultyColorBar.backgroundColor = techRatingColor
            
            difficultyLabel.text = difficulty.name
            difficultyLabel.textColor = TechRatingColorMapper.getTechRatingForegroundColor(techRatingCode: difficulty.code)
            difficultyView.backgroundColor = TechRatingColorMapper.getTechRatingColor(techRatingCode: difficulty.code)
        }
        else {
           difficultyColorBar.backgroundColor = UIColor.white
            difficultyLabel.text = "UNKNOWN"
            difficultyView.backgroundColor = .white
        }
        bookmarkButton.isSelected = basicTrailInfo?.userData?.favorite == true
    }
        
    // Description with a UITextView (Trail Info)
    public static func setDisplayFieldValues(trailTitleLabel: inout UILabel, descriptionTextView: inout UITextView, distanceLabel: inout UILabel, userRatings: inout RatingView, userRatingCountLabel: inout UILabel, userRatingValueLabel: inout UILabel, difficultyLabel: inout UILabel, difficultyView: inout UIView, basicTrailInfo: TrailBasicInfo?, trail: Trail?) {

        setDisplayFieldValuesPartial(trailTitleLabel: &trailTitleLabel, distanceLabel: &distanceLabel, basicTrailInfo: basicTrailInfo)

        difficultyView.layer.cornerRadius = difficultyView.bounds.height / 2

        if let description = basicTrailInfo?.description {
            if let history = trail?.info.history, !history.isEmpty {
                let historyTitle = "<br/><br/><h3>History</h3>"
                descriptionTextView.attributedText = (description + historyTitle + history).htmlAttributed(family: "-apple-system", size: 14, color: UIColor.Inactive!)
            } else {
                descriptionTextView.attributedText = description.htmlAttributed(family: "-apple-system", size: 14, color: UIColor.Inactive!)
            }
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
            difficultyLabel.textColor = TechRatingColorMapper.getTechRatingForegroundColor(techRatingCode: difficulty.code)
            difficultyView.backgroundColor = TechRatingColorMapper.getTechRatingColor(techRatingCode: difficulty.code)
        }
        else {
            difficultyLabel.text = "UNKNOWN"
            difficultyView.backgroundColor = .white
        }
    }
}
