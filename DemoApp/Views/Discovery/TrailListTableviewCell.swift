//
//  TrailListTableviewCell.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/8/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import StarryStars

class TrailListTableviewCell: UICollectionViewCell {
    @IBOutlet weak var trailTitle: UILabel!
    var ratingStars: RatingView = RatingView()
    @IBOutlet weak var trailDistanceLabel: UILabel!
    @IBOutlet weak var trailTimeLabel: UILabel!
    @IBOutlet weak var trailElevationLabel: UILabel!
    @IBOutlet weak var trailDescription: UILabel!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var difficultyColorBarLabel: UILabel!
    @IBOutlet weak var difficultyView: UIView!
    @IBOutlet weak var difficultyLabel: UILabel!

    static let cellIdentifier = "TrailInfoCell"
    static let cellXibName = "TrailListTableviewCell"
    
    weak var delegate: TrailListViewDelegate?
    var trail: TrailBasicInfo?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.contentView.layer.cornerRadius = 10
        self.contentView.clipsToBounds = true
        self.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(containerPicked)))

        bookmarkButton.layer.cornerRadius = 15.0
        bookmarkButton.layer.borderColor = UIColor.black.cgColor
        bookmarkButton.layer.borderWidth = 1.0
        bookmarkButton.imageView?.image = UIImage.bookmarkImage

        difficultyView.layer.cornerRadius = difficultyView.bounds.height / 2
    }

    @objc func containerPicked() {
        if let trail = self.trail  {
            self.delegate?.didTapTrailInfo(basicInfo: trail)
        }
    }

    @IBAction func bookmarkPicked(_ sender: Any) {
        if let trail = self.trail  {
            guard let userData = trail.userData ?? (try? TrailInfoRepo.loadTrailUserData(trailId: trail.id)) else {
                return
            }

            // Toggle value
            let toggleFavorite = !(userData.favorite ?? false)
            let service = ServiceFactory.getTrailService()
            service.setTrailFavorite(trailId: trail.id, favorite: toggleFavorite) { (result) in
                if case let .success(value) = result {
                    // Update the value also in the View
                    let updatedUserData = self.trail?.userData?.copyWithFavorite(favorite: value.favorite)
                    self.trail?.userData = updatedUserData
                    self.bookmarkButton.isSelected = toggleFavorite
                } else {
                    print("Trail update failed: \(result.buildErrorMessage() ?? "unknown reason")")
                }
            }
        }
    }
}
