//
//  TrailInfoView.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 20/12/2019.
//  Copyright © 2019 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Reachability

protocol TrailInfoViewDelegate: class {
    func didTapTrailInfoBackButton()
    func getOfflineMapManager() -> IOfflineMapManager
}

class TrailInfoViewController: UIViewController {
    
    @IBOutlet weak var trailTitleLabel: UILabel!
    @IBOutlet weak var trailDescriptionTextView: UITextView!
    @IBOutlet weak var trailDistanceLabel: UILabel!
    @IBOutlet weak var trailRatingValueLabel: UILabel!
    @IBOutlet weak var trailUserRatingCountLabel: UILabel!
    @IBOutlet weak var trailUserRatingStarOne: UIImageView!
    @IBOutlet weak var trailUserRatingStarTwo: UIImageView!
    @IBOutlet weak var trailUserRatingStarThree: UIImageView!
    @IBOutlet weak var trailUserRatingStarFour: UIImageView!
    @IBOutlet weak var trailUserRatingStarFive: UIImageView!
    @IBOutlet weak var trailImagesCollectionView: UICollectionView!
    @IBOutlet weak var difficultyLabel: UILabel!
    
    @IBOutlet weak var getThereButton: UIButton!
    @IBOutlet weak var savedButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var startNavigationButton: UIButton!
    
    @IBOutlet weak var trailDetailsTableView: UITableView!
    
    @IBOutlet weak var trailDescriptionButton: UIButton!
    @IBOutlet weak var trailDetailsButton: UIButton!
    @IBOutlet weak var trailForecastButton: UIButton!
    @IBOutlet weak var trailReviewButton: UIButton!
    
    weak var delegate: TrailInfoViewDelegate?
    
    var basicTrailInfo: TrailBasicInfo?
    
    var trailDetails: TrailDetails?
    
    var reachability: Reachability!
    
    var trailMedia: Array<Media>?
    
    enum ViewState {
        case description
        case details
        case forecast
        case reviews
    }
    
    var viewState: ViewState = .description
    
    override func viewDidLoad() {
        
        // Reachability is used to check if internet connection is available
        self.reachability = try! Reachability()
                
        getThereButton.imageView?.image = UIImage.getThereImage
        
        savedButton.imageView?.image = UIImage.bookmarkImage
        
        downloadButton.imageView?.image = UIImage.cacheDownloadImage
        
        startNavigationButton.imageView?.image = UIImage.startNavigationImage
        
        var userRatingsContainer = UserRatingContainer(one: trailUserRatingStarOne, two: trailUserRatingStarTwo, three: trailUserRatingStarThree, four: trailUserRatingStarFour, five:trailUserRatingStarFive)
        TrailInfoDisplay.setDisplayFieldValues(trailTitleLabel: &trailTitleLabel, descriptionTextView: &trailDescriptionTextView, distanceLabel: &trailDistanceLabel, userRatings: &userRatingsContainer, userRatingCountLabel: &trailUserRatingCountLabel, userRatingValueLabel: &trailRatingValueLabel, difficultyLabel: &difficultyLabel, basicTrailInfo: basicTrailInfo)
        
        self.downloadButton.isEnabled = false
        self.downloadButton.alpha = 0
        
        self.trailImagesCollectionView.register(UINib(nibName: TrailImageCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TrailImageCollectionViewCell.cellIdentifier)
        
        if let trailId = self.basicTrailInfo?.id {
            
            do {
                if let trail = try ServiceFactory.getTrailService().getTrailById(trailId) {
                    self.trailMedia = trail.media
                    self.trailImagesCollectionView.reloadData()
                }
            }
            catch {
                fatalError("\(error)")
            }
            
            // Offline map status is asynchronous operation. We are hiding the downloadButton until we
            // successfully retrieve status of the trail cache
            
            self.delegate?.getOfflineMapManager().getOfflineMapStatus(type: .TRAIL, trailId: trailId) { (status, error) in
                if let status = status {
                    
                    // Configure download button
                    
                    self.configureDownloadButton(mapStatus: status)
                    
                    // Monitor downloading progress. If the delegate is set while the download is in progress
                    // the manager will trigger onProgressChanged immediatelly
                    
                    self.delegate?.getOfflineMapManager().progressDelegate = self
                } else {
                    fatalError("Could not get offline map status: \(String(describing: error))")
                }
            }
        }
    }
    
    private func configureDownloadButton(mapStatus: OfflineMapStatus, progressPercents: Int = 0) {
        self.downloadButton.isEnabled = true
        self.downloadButton.alpha = 1
        
        switch mapStatus {
        case .FAILED, .NOT_CACHED:
            self.downloadButton.setImage(UIImage.cacheDownloadImage, for: .normal)
            self.downloadButton.setTitle("DOWNLOAD", for: .normal)
        case .WAITING:
            self.downloadButton.setImage(UIImage.cacheProgressImage, for: .normal)
            self.downloadButton.setTitle("QUEUED", for: .normal)
        case .IN_PROGRESS:
            self.downloadButton.setImage(UIImage.cacheProgressImage, for: .normal)
            self.downloadButton.setTitle("\(progressPercents) %", for: .normal)
        case .COMPLETE:
            self.downloadButton.setImage(UIImage.cacheDeleteImage, for: .normal)
            self.downloadButton.setTitle("CACHED", for: .normal)
        }
    }
    
    @IBAction func didTapDownload(_ sender: Any) {
        guard let offlineMapManager = delegate?.getOfflineMapManager() else {
            fatalError("Could not get offline map manager")
        }
        guard let trailId = self.basicTrailInfo?.id else {
            fatalError("TrailId not set")
        }
        
        // Because download, delete and cancel are asynchronous we want to disable the downloadButton temporarily
        
        downloadButton.isEnabled = false
        
        offlineMapManager.getOfflineMapStatus(type: .TRAIL, trailId: trailId) { (status, error) in
            self.downloadButton.isEnabled = true
            if let status = status {
                do {
                    switch status {
                    case .NOT_CACHED, .FAILED:
                        // Please note the estimate is often very inaccurate!
                        let estimateBytes = try offlineMapManager.estimateTrailCacheSize(trailId: trailId)
                        let estimateText = estimateBytes.humanFileSize()
                        
                        // For the simplification require always 200 MB of free space
                        let mb200: Int64 = 209715200
                        let freeBytes: Int64 = offlineMapManager.getFreeDiskSpace()
                        if freeBytes < mb200 {
                            AlertUtils.showAlert(viewController: self, title: "Low Space", message: "There is not enough disk space to download the trail")
                        } else {
                            AlertUtils.showPrompt(viewController: self, title: "Download", message: "Would you like to download trail map cache (~\(estimateText))?", confirmHandler: {
                                
                                self.downloadButton.isEnabled = false
                                
                                // Download is asynchronous. The callback is called as soon as the download starts.
                                
                                offlineMapManager.downloadOfflineMap(type: .TRAIL, trailId: trailId) { (error) in
                                    self.downloadButton.isEnabled = true
                                    if let error = error {
                                        self.showError(error)
                                    } else {
                                        self.configureDownloadButton(mapStatus: .WAITING)
                                    }
                                }
                            })
                        }
                    case .COMPLETE:
                        
                        // For completed cache we show size of the cache with option to delete the cache
                        
                        offlineMapManager.getOfflineMapStorageSize(type: .TRAIL, trailId: trailId) { (size, error) in
                            if let error = error {
                                self.showError(error)
                            } else {
                                AlertUtils.showPrompt(viewController: self, title: "Remove Offline Cache?", message: "The trail is already cached. Cache size: \(Int64(size).humanFileSize()). Do you want to remove the cache?", confirmHandler: {
                                    
                                    self.downloadButton.isEnabled = false
                                    
                                    // Delete cache is asynchronous and can take a while for large caches
                                    
                                    offlineMapManager.deleteOfflineMap(type: .TRAIL, trailId: trailId) { (success, error) in
                                        self.downloadButton.isEnabled = true
                                        if let error = error {
                                            self.showError(error)
                                        } else {
                                            self.configureDownloadButton(mapStatus: .NOT_CACHED)
                                        }
                                    }
                                })
                            }
                        }
                    case .WAITING, .IN_PROGRESS:
                        
                        // Cache can be waiting in queue or can be downloading.
                        // The deleteOfflineCache will either remove it from the queue or cancel the download.
                        
                        AlertUtils.showPrompt(viewController: self, title: "Cancel Offline Cache?", message: "Downloading trail cache. Do you want to cancel?", confirmHandler: {
                            
                            self.downloadButton.isEnabled = false
                            
                            // Delete cache is asynchronous
                            
                            offlineMapManager.deleteOfflineMap(type: .TRAIL, trailId: trailId) { (success, error) in
                                self.downloadButton.isEnabled = true
                                if let error = error {
                                    self.showError(error)
                                } else {
                                    self.configureDownloadButton(mapStatus: .NOT_CACHED)
                                }
                            }
                        })
                    }
                } catch {
                    fatalError("\(error)")
                }
            } else {
                fatalError("\(String(describing: error))")
            }
        }
    }
    
    @IBAction func didTapSaved(_ sender: Any) {
    }
    
    @IBAction func didTapGetThere(_ sender: Any) {
    }
    
    @IBAction func didTapStartNavigation(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "Driving") as? DrivingViewController {
            vc.title = "Trail Info"
            vc.trailId = self.basicTrailInfo?.id
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .overCurrentContext
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapTrailDescription() {
        setViewState(.description)
    }
    
    @IBAction func didTapTrailDetails() {
        setViewState(.details)
    }
    
    @IBAction func didTapTrailForecast() {
        setViewState(.forecast)
    }
    
    @IBAction func didTapTrailReviews() {
        setViewState(.reviews)
    }
    
    @IBAction func didTapBackButton() {
        self.delegate?.didTapTrailInfoBackButton()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent == self.navigationController?.parent {
            self.delegate?.didTapTrailInfoBackButton()
            print("Back tapped")
        }
    }
    
    private func setViewState(_ newViewState: ViewState) {
        self.trailDescriptionButton.isSelected = false
        self.trailDescriptionTextView.isHidden = true
        self.trailDetailsButton.isSelected = false
        self.trailDetailsTableView.isHidden = true
        self.trailForecastButton.isSelected = false
        self.trailReviewButton.isSelected = false
        
        switch newViewState {
        case .description:
            self.trailDescriptionButton.isSelected = true
            self.trailDescriptionTextView.isHidden = false
        case .details:
            self.trailDetailsButton.isSelected = true
            self.trailDetailsTableView.isHidden = false
            self.trailDetailsTableView.delegate = self
            self.trailDetailsTableView.dataSource = self
            
            if let trailId = self.basicTrailInfo?.id {
                if self.trailDetails == nil {
                    self.trailDetails = TrailDetails(trailId: trailId)
                }
            }
            
            self.trailDetailsTableView.reloadData()
        case .forecast:
            self.trailForecastButton.isSelected = true
        case .reviews:
            self.trailReviewButton.isSelected = true
        }
        self.viewState = newViewState
    }
}

extension TrailInfoViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let trailDetails = self.trailDetails else {
            return 0
        }
        return 15 + trailDetails.waypoints.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let trailDetails = self.trailDetails else {
            return 0
        }
        if let section = trailDetails.getSection(sectionId: section) {
            if section.values.count == 0 {
                return 1 // Show Empty Section note
            } else {
                return section.values.count
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let trailDetails = self.trailDetails, let section = trailDetails.getSection(sectionId: section) {
            return section.name
        } else {
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        if let trailDetails = self.trailDetails, let section = trailDetails.getSection(sectionId: indexPath.section) {
            if section.values.count == 0 {
                cell.textLabel?.text = "No information is available"
            } else {
                cell.textLabel?.text = section.values[indexPath.row].key
                var value = section.values[indexPath.row].value
                if value.count == 0 {
                    value = "N/A"
                }
                cell.detailTextLabel?.text = value
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let trailDetails = self.trailDetails, let section = trailDetails.getSection(sectionId: indexPath.section) {
            if section.values.count > 0 {
                let key = section.values[indexPath.row].key
                let value = section.values[indexPath.row].value
                if value.count > 0 {
                    let alert = UIAlertController(title: key, message: value, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                    self.present(alert, animated: false, completion: nil)
                }
            }
        }
        return nil
    }
    
    
}

extension TrailInfoViewController : CacheProgressDelegate {
    func onProgressChanged(progress: Double, mapType: OfflineMapType, trailId: Int64) {
        if trailId == self.basicTrailInfo?.id {
            configureDownloadButton(mapStatus: .IN_PROGRESS, progressPercents: Int(progress * 100))
        }
    }
    
    func onError(error: [OfflineResourceError], mapType: OfflineMapType, trailId: Int64) {
        if trailId == self.basicTrailInfo?.id {
            let message = error.map ({ (resourceError) -> String in
                return "\(resourceError.offlineResource.getResourceTypeName()) failed \(resourceError.error)"
            }).joined(separator: "\n")
            showError(message.toError())
            configureDownloadButton(mapStatus: .FAILED)
        }
    }
    
    func onComplete(mapType: OfflineMapType, trailId: Int64) {
        if trailId == self.basicTrailInfo?.id {
            configureDownloadButton(mapStatus: .COMPLETE)
        }
    }
}

extension TrailInfoViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.trailMedia?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrailImageCollectionViewCell.cellIdentifier, for: indexPath) as! TrailImageCollectionViewCell
        if let trailMediaArray = self.trailMedia {
            cell.initWithMedia(media: trailMediaArray[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let media = self.trailMedia?[indexPath.row] {
            if let vc = UIStoryboard(name: "Main", bundle: nil) .
                instantiateViewController(withIdentifier: "PhotoViewController") as? PhotoViewController {
                vc.mediaLoader = MediaLoader(media: media, type: .FullImage)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
