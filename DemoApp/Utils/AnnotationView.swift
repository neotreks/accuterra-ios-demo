//
//  AnnotationView.swift
//  DemoApp
//
//  Created by Brian Elliott on 6/10/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import MapLibre
import SwiftUI

class AnnotationView: MLNAnnotationView {
    var isTrailHead:Bool
    var path: UIBezierPath!

    init(reuseIdentifier: String?, isTrailHead:Bool) {
        self.isTrailHead = isTrailHead
        super.init(reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        self.isTrailHead = false
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        drawMarkerWithFrame(frame: rect)
    }
    
    private func drawMarkerWithFrame(frame:CGRect) {
        
        let context = UIGraphicsGetCurrentContext()!
        
        context.saveGState()
        let resizedFrame: CGRect = ResizeBehavior.aspectFit.apply(rect: CGRect(x: 0, y: 0, width: 64, height: 100), target: frame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 64, y: resizedFrame.height / 100)
        
        if isTrailHead {
            context.restoreGState()
            return
        }

        //// Color Declarations
        let fillColor = UIColor(red: 0.774, green: 0.404, blue: 0.380, alpha: 1.000)
        let fillColor2 = UIColor(red: 1.000, green: 0.999, blue: 0.996, alpha: 1.000)


        //// red-pin Group
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 64.31, y: 34.83))
        bezierPath.addCurve(to: CGPoint(x: 32.15, y: 100.11), controlPoint1: CGPoint(x: 64.31, y: 64.11), controlPoint2: CGPoint(x: 32.15, y: 100.11))
        bezierPath.addCurve(to: CGPoint(x: -0.02, y: 34.83), controlPoint1: CGPoint(x: 32.15, y: 100.11), controlPoint2: CGPoint(x: -0.02, y: 64.11))
        bezierPath.addCurve(to: CGPoint(x: 32.15, y: 0.11), controlPoint1: CGPoint(x: -0.02, y: 15.65), controlPoint2: CGPoint(x: 12.97, y: 0.11))
        bezierPath.addCurve(to: CGPoint(x: 64.31, y: 34.83), controlPoint1: CGPoint(x: 51.32, y: 0.11), controlPoint2: CGPoint(x: 64.31, y: 15.65))
        bezierPath.close()
        fillColor.setFill()
        bezierPath.fill()

        let ovalPath = UIBezierPath(ovalIn: CGRect(x: 20.15, y: 21.35, width: 24, height: 24))
        fillColor2.setFill()
        ovalPath.fill()
        
        context.restoreGState()
    }
    
    public enum ResizeBehavior: Int {
        case aspectFit /// The content is proportionally resized to fit into the target rectangle.
        case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
        case stretch /// The content is stretched to match the entire target rectangle.
        case center /// The content is centered in the target rectangle, but it is NOT resized.

        public func apply(rect: CGRect, target: CGRect) -> CGRect {
            if rect == target || target == CGRect.zero {
                return rect
            }

            var scales = CGSize.zero
            scales.width = abs(target.width / rect.width)
            scales.height = abs(target.height / rect.height)

            switch self {
                case .aspectFit:
                    scales.width = min(scales.width, scales.height)
                    scales.height = scales.width
                case .aspectFill:
                    scales.width = max(scales.width, scales.height)
                    scales.height = scales.width
                case .stretch:
                    break
                case .center:
                    scales.width = 1
                    scales.height = 1
            }

            var result = rect.standardized
            result.size.width *= scales.width
            result.size.height *= scales.height
            result.origin.x = target.minX + (target.width - result.width) / 2
            result.origin.y = target.minY + (target.height - result.height) / 2
            return result
        }
    }
}
