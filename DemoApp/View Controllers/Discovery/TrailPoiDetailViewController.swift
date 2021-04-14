//
//  TrailPoiDetailViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 10/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class TrailPoiDetailViewController: UIViewController {

    // MARK:- Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var typeLabel: UILabel!

    // MARK:- Properties
    var trailDriveWaypoint: TrailDriveWaypoint!

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "POI"
        
        self.nameLabel.text = trailDriveWaypoint.point.name
        self.descriptionLabel.text = trailDriveWaypoint.description
        self.typeLabel.text = trailDriveWaypoint.point.type.name
        
        self.collectionView.register(UINib(nibName: TrailImageCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TrailImageCollectionViewCell.cellIdentifier)
        self.collectionView.reloadData()
    }
}

// MARK:- UICollectionView extensions
extension TrailPoiDetailViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.trailDriveWaypoint?.point.media.count ?? 0
    }
     
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrailImageCollectionViewCell.cellIdentifier, for: indexPath) as! TrailImageCollectionViewCell
        cell.bindView(media: trailDriveWaypoint.point.media[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let media = self.trailDriveWaypoint.point.media[indexPath.row]
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "PhotoViewController") as? PhotoViewController {
            vc.mediaLoader = TrailMediaLoader(media: media, variant: .DEFAULT)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
