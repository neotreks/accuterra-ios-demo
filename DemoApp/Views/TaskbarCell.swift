//
//  TaskbarCollectionViewCell.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/19/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

class TaskbarCell: UICollectionViewCell {
    
    static let selectedBarHeight = 7.0
    static let titleFontSize = 9.0

    var icon: UIImageView?
    var title: UILabel?

    var iconUnselected: UIImage?
    var iconSelected: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        title = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 0))
        title?.font = UIFont.systemFont(ofSize: TaskbarCell.titleFontSize)
        title?.textAlignment = .center
        title?.textColor = UIColor.TaskbarTextColor
        title?.translatesAutoresizingMaskIntoConstraints = false
        if let titleLabel = title {
            contentView.addSubview(titleLabel)
            addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        }

        icon = UIImageView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 22))
        icon?.image = iconUnselected
        icon?.contentMode = .scaleAspectFit
        icon?.translatesAutoresizingMaskIntoConstraints = false
        if let iconImageView = icon {
            contentView.addSubview(iconImageView)
            addConstraint(NSLayoutConstraint(item: iconImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: iconImageView, attribute: .bottom, relatedBy: .equal, toItem: title, attribute: .top, multiplier: 1, constant: -8))
            addConstraint(NSLayoutConstraint(item: iconImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 22)
)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            title?.textColor = isHighlighted ? UIColor.TaskbarActiveTextColor: UIColor.TaskbarTextColor
            title?.font = isHighlighted ? UIFont.systemFont(ofSize: TaskbarCell.titleFontSize, weight: .semibold) : UIFont.systemFont(ofSize: TaskbarCell.titleFontSize, weight: .regular)
            icon?.image = isHighlighted ? iconSelected : iconUnselected
        }
    }
    
    override var isSelected: Bool {
        didSet {
            title?.textColor = isSelected ? UIColor.TaskbarActiveTextColor : UIColor.TaskbarTextColor
            title?.font = isSelected ? UIFont.systemFont(ofSize: TaskbarCell.titleFontSize, weight: .semibold) : UIFont.systemFont(ofSize: TaskbarCell.titleFontSize, weight: .regular)
            icon?.image = isSelected ? iconSelected : iconUnselected
        }
    }
    
}
