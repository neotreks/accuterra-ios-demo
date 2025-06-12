//
//  UserLocationButton.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 7/8/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import MapLibre

class UserLocationButton: UIButton {
    private var arrow: CAShapeLayer?
    private let buttonSize: CGFloat

    // Initializer to create the user tracking mode button
    init(buttonSize: CGFloat) {
        self.buttonSize = buttonSize
        super.init(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        self.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        self.layer.cornerRadius = buttonSize / 2
        self.dropShadow()

        let arrow = CAShapeLayer()
        arrow.path = arrowPath()
        arrow.lineWidth = 1
        arrow.lineJoin = CAShapeLayerLineJoin.round
        arrow.bounds = CGRect(x: 0, y: 0, width: buttonSize / 2, height: buttonSize / 2)
        arrow.position = CGPoint(x: (buttonSize / 2) - 0.4, y: buttonSize / 2)
        arrow.shouldRasterize = true
        arrow.rasterizationScale = UIScreen.main.scale
        arrow.drawsAsynchronously = true

        self.arrow = arrow

        // Update arrow for initial tracking mode
        updateArrowForTrackingMode(mode: .none)
        layer.addSublayer(self.arrow!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Create a new bezier path to represent the tracking mode arrow,
    // making sure the arrow does not get drawn outside of the
    // frame size of the UIButton.
    private func arrowPath() -> CGPath {
        let bezierPath = UIBezierPath()
        let max: CGFloat = buttonSize / 2
        bezierPath.move(to: CGPoint(x: max * 0.5, y: 0))
        bezierPath.addLine(to: CGPoint(x: max * 0.1, y: max))
        bezierPath.addLine(to: CGPoint(x: max * 0.5, y: max * 0.65))
        bezierPath.addLine(to: CGPoint(x: max * 0.9, y: max))
        bezierPath.addLine(to: CGPoint(x: max * 0.5, y: 0))
        bezierPath.close()

        return bezierPath.cgPath
    }

    // Update the arrow's color and rotation when tracking mode is changed.
    func updateArrowForTrackingMode(mode: MLNUserTrackingMode) {
        let activePrimaryColor = UIColor.Active!
        let disabledPrimaryColor = UIColor.black
        let disabledSecondaryColor = UIColor.clear
        let rotatedArrow = CGFloat(0.66)

        switch mode {
        case .none:
            updateArrow(fillColor: disabledSecondaryColor, strokeColor: disabledPrimaryColor, rotation: rotatedArrow)
        case .follow:
            updateArrow(fillColor: disabledPrimaryColor, strokeColor: disabledPrimaryColor, rotation: rotatedArrow)
        case .followWithHeading:
            updateArrow(fillColor: activePrimaryColor, strokeColor: activePrimaryColor, rotation: rotatedArrow)
        case .followWithCourse:
            updateArrow(fillColor: activePrimaryColor, strokeColor: activePrimaryColor, rotation: 0)
        @unknown default:
            fatalError("Unknown user tracking mode")
        }
    }

    func updateArrow(fillColor: UIColor, strokeColor: UIColor, rotation: CGFloat) {
        guard let arrow = arrow else { return }
        arrow.fillColor = fillColor.cgColor
        arrow.strokeColor = strokeColor.cgColor
        arrow.setAffineTransform(CGAffineTransform.identity.rotated(by: rotation))

        // Re-center the arrow within the button if rotated
        if rotation > 0 {
            arrow.position = CGPoint(x: buttonSize / 2, y: buttonSize / 2 - 2)
        }

        layoutIfNeeded()
    }
}
