//
//  TrailStyleProvider.swift
//  DemoApp(Develop)
//
//  Created by Brian Elliott on 4/8/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import MapLibre

/**
* A custom style provider used for imaginary base map
*/
class AccuTerraSatelliteStyleProvider: AccuTerraStyleProviderTrailCollection {
    
    // Trail Path properties
    override func getTrailProperties(type:TrailLayerStyleType, layer: MLNLineStyleLayer) -> MLNLineStyleLayer {
        if type == TrailLayerStyleType.TRAIL_PATH {
            layer.lineColor = NSExpression(forConstantValue: UIColor.red)
            layer.lineWidth = NSExpression(forConstantValue: 1.0)
            layer.minimumZoomLevel = 12
            return layer
        }
        else if type == TrailLayerStyleType.SELECTED_TRAIL_PATH {
            layer.lineColor = NSExpression(forConstantValue: UIColor.orange)
            layer.lineWidth = NSExpression(forConstantValue: 2.0)
            return layer
        }
        else if type == TrailLayerStyleType.TRAIL_HEAD {
            return layer
        }
        else {
            return layer
        }
    }
    
    // Unclustered marker and POIs image
    override func getPoiImage(type: TrailPoiStyleType) -> UIImage {
        switch type {
        case .TRAIL_HEAD:
            let image = UIImage(named: "location-pin") ?? UIImage()
            return image
        case .TRAIL_POI:
            let image = UIImage(named: "location-pin") ?? UIImage()
            return image
        case .SELECTED_TRAIL_POI:
            let image = UIImage(named: "ic_google_location_pin") ?? UIImage()
            return image
        }
    }
    
    // Unclustered marker or POI properties
    override func getPoiProperties(type: TrailPoiStyleType, layer: MLNSymbolStyleLayer) -> MLNSymbolStyleLayer {
        if type == TrailPoiStyleType.TRAIL_HEAD {
            layer.iconScale = NSExpression(forConstantValue: 1.0)
            layer.iconOpacity = NSExpression(forConstantValue: 0.85)
            layer.iconColor = NSExpression(forConstantValue: UIColor(hex: "00ff00"))
            layer.iconIgnoresPlacement = NSExpression(forConstantValue: true)
            layer.iconAnchor = NSExpression(forConstantValue: NSNumber(value: MLNIconAnchor.bottom.rawValue))
            layer.iconAllowsOverlap = NSExpression(forConstantValue: true)
            return layer
        }
        else if type == TrailPoiStyleType.TRAIL_POI || type == TrailPoiStyleType.SELECTED_TRAIL_POI {
            layer.iconScale = NSExpression(forConstantValue: 1.0)
            layer.iconOpacity = NSExpression(forConstantValue: 0.85)
            layer.iconColor = NSExpression(forConstantValue: UIColor(hex: "0000ff"))
            layer.iconIgnoresPlacement = NSExpression(forConstantValue: true)
            layer.iconAnchor = NSExpression(forConstantValue: NSNumber(value: MLNIconAnchor.bottom.rawValue))
            layer.iconAllowsOverlap = NSExpression(forConstantValue: true)
            return layer
            }
        else {
            return layer
        }
    }
        
    // Cluster properties
    override func getTrailMarkerProperties(type: TrailMarkerStyleType, layer: MLNVectorStyleLayer) -> MLNVectorStyleLayer {
        if type == TrailMarkerStyleType.CLUSTER {
            if layer is MLNCircleStyleLayer{
                let circleLayer = layer as! MLNCircleStyleLayer
                circleLayer.circleRadius = NSExpression(forConstantValue: NSNumber(value: iconSize / 2))
                circleLayer.circleOpacity = NSExpression(forConstantValue: 0.65)
                circleLayer.circleColor = NSExpression(forConstantValue: UIColor(hex: "777777"))
                return circleLayer
            }
            else {
                return layer
            }
        }
        else if type == TrailMarkerStyleType.CLUSTER_LABEL {
            if layer is MLNSymbolStyleLayer{
                let symbolLayer = layer as! MLNSymbolStyleLayer
                symbolLayer.text = NSExpression(format: "CAST(point_count, 'NSString')")
                symbolLayer.textFontSize = NSExpression(forConstantValue: NSNumber(value: iconSize/2))
                symbolLayer.textColor = NSExpression(forConstantValue: UIColor.yellow)
                symbolLayer.textIgnoresPlacement = NSExpression(forConstantValue: true)
                symbolLayer.textAllowsOverlap = NSExpression(forConstantValue: true)
                if isMapbox {
                    symbolLayer.textFontNames = NSExpression(forConstantValue: ["Open Sans Regular","Arial Unicode MS Regular"])
                } else {
                    symbolLayer.textFontNames = NSExpression(forConstantValue: ["Roboto Regular"])
                }
                return symbolLayer
            }

            else {
                return layer
            }
        }
        else {
            return layer
        }
    }
    
    override func modifyFeature(feature: MLNPointFeature, marker: TrailMarker) {
        let trailBasicInfo = try? ServiceFactory.getTrailService().getTrailBasicInfoById(marker.trailId)
        let difficulty = getDifficulty(trail: trailBasicInfo)
        feature.attributes["difficulty"] = difficulty
    }
    
    private func getDifficulty(trail: TrailBasicInfo?) -> String {
        if let difficultyLevel = trail?.techRatingHigh.level {
            return String(difficultyLevel)
        } else {
            return "No trail found"
        }
    }
}
