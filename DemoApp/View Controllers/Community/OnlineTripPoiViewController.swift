//
//  OnlineTripPoiViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 09.01.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class OnlineTripPoiViewController: UIViewController {

    // MARK:- Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var typeLabel: UILabel!

    // MARK:- Properties
    var tripPoint: TripPoint!

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.register(UINib(nibName: TripMediaCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TripMediaCollectionViewCell.cellIdentifier)
        
        self.title = "POI"
        
        self.nameLabel.text = tripPoint.name
        self.descriptionLabel.text = tripPoint.description
        self.typeLabel.text = tripPoint.pointType.name
        self.collectionView.reloadData()
    }
}

// MARK:- UICollectionView extension
extension OnlineTripPoiViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tripPoint.media.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TripMediaCollectionViewCell.cellIdentifier, for: indexPath) as! TripMediaCollectionViewCell
        cell.bindView(media: tripPoint.media[indexPath.row], mediaVariant: .THUMBNAIL, delegate: self)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let media = self.tripPoint.media[indexPath.row]
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "PhotoViewController") as? PhotoViewController {
            vc.mediaLoader = MediaLoaderFactory.tripMediaLoader(media: media, variant: .DEFAULT)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK:- TripMediaCollectionViewCellDelegate extension
extension OnlineTripPoiViewController : TripMediaCollectionViewCellDelegate {
    func tripMediaDeletePressed(media: TripMedia) {
        // not implemented here
    }
    
    func canEditMedia() -> Bool {
        return false
    }
}
