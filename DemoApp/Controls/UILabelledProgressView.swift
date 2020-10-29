//
//  UILabelledProgressView.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 26/05/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class UILabelledProgressView: UIControl {
    
    private var label: UILabel?
    private var progressView: UIProgressView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    @IBInspectable var text: String? {
        didSet {
            self.label?.text = text
        }
    }
    
    @IBInspectable var progress: Float = 0 {
        didSet {
            self.progressView?.progress = progress
        }
    }
    
    override func prepareForInterfaceBuilder() {
        setupUI()
        progress = 0.5
        text = "Downloading 50%"
    }
    
    //MARK: Private Methods
    
    private func setupUI() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // progress
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.transform = progressView.transform.scaledBy(x: 1, y: 30)
        
        self.progressView = progressView
        
        let progressViewCenterVerticallyConstraint = NSLayoutConstraint(item: progressView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        let progressViewLeadingConstraint = NSLayoutConstraint(item: progressView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        let progressViewTrailingConstraint = NSLayoutConstraint(item: progressView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        
        self.addSubview(progressView)
        NSLayoutConstraint.activate([progressViewCenterVerticallyConstraint, progressViewLeadingConstraint, progressViewTrailingConstraint])
        
        // Label
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.text = ""
        label.textColor = UIColor.white
        self.label = label
        
        let labelLeadingConstraint = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 5)
        let labelCenterVerticallyConstraint = NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addSubview(label)
        NSLayoutConstraint.activate([labelLeadingConstraint, labelCenterVerticallyConstraint])
    }
}
