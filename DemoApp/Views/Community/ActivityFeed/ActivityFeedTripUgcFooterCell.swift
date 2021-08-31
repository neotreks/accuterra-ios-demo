//
//  ActivityFeedTripUgcFooterCell.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 22.12.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

protocol ActivityFeedTripUgcFooterCellDelegate: AnyObject {
    func onLikeClicked(item: ActivityFeedItem)
    func onPhotosClicked(item: ActivityFeedItem)
}

class ActivityFeedTripUgcFooterCell: UITableViewCell {

    @IBOutlet weak var likesIcon: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var photosLabel: UILabel!
    
    private var item: ActivityFeedTripUgcFooterItem?
    
    weak var delegate: ActivityFeedTripUgcFooterCellDelegate?
    
    @IBAction func didTapLike() {
        guard let item = self.item else {
            return
        }
        delegate?.onLikeClicked(item: item)
    }
    
    @IBAction func didTapPhoto() {
        guard let item = self.item else {
            return
        }
        delegate?.onPhotosClicked(item: item)
    }
    
    func bindView(item: ActivityFeedTripUgcFooterItem) {
        self.item = item
        guard let data = item.data else {
            return
        }
        // Data
        likesLabel.text = "\(data.trip.likesCount) Likes"
        commentsLabel.text = "\(data.trip.commentsCount) Comments"
        photosLabel.text = "\(data.trip.imageResourceUuids.count) Photos"
        // Like icon
        likesIcon.tintColor = data.trip.userLike ? UIColor.Active : UIColor.Inactive
    }
}
