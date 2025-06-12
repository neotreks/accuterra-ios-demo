//
//  TrailInfoView.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 20/12/2019.
//  Copyright © 2019 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import StarryStars
import CoreLocation

protocol TrailInfoViewDelegate: AnyObject {
    func didTapTrailInfoBackButton()
}

class TrailInfoViewController: LocationViewController {

    // MARK: - Outlets
    @IBOutlet weak var trailTitleLabel: UILabel!
    @IBOutlet weak var trailDescriptionTextView: UITextView!
    @IBOutlet weak var trailDistanceLabel: UILabel!
    private var trailRatingValueLabel: UILabel = UILabel()
    private var trailUserRatingCountLabel: UILabel = UILabel()
    private var trailUserRatingStar: RatingView = RatingView()
    @IBOutlet weak var trailImagesCollectionView: UICollectionView!
    @IBOutlet weak var difficultyLabel: UILabel!
    @IBOutlet weak var difficultyView: UIView!
    @IBOutlet weak var getThereButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var startNavigationButton: UIButton!
    @IBOutlet weak var trailDescriptionButton: UIButton!
    @IBOutlet weak var trailPoisButton: UIButton!
    @IBOutlet weak var trailDetailsButton: UIButton!
    @IBOutlet weak var trailMapImageButton: UIButton!
    @IBOutlet weak var trailUgcButton: UIButton!
    @IBOutlet weak var trailDetailsTableView: UITableView!
    @IBOutlet weak var trailUGCView: UIView!
    @IBOutlet weak var trailUGCRatingView: RatingView!
    @IBOutlet weak var trailUGCRatingLabel: UILabel!
    @IBOutlet weak var trailUGCCommentsTableView: UITableView!
    @IBOutlet weak var trailUGCCommentsLabel: UILabel!
    @IBOutlet weak var trailMapImageView: UIImageView!

    
    // MARK: - Public properties
    weak var delegate: TrailInfoViewDelegate?
    var trailId: Int64?
    
    // MARK: - Private properties
    private let TAG = LogTag(subsystem: "ATDemoApp", category: String(describing: self))
    private var trail: Trail?
    private var trailBasicInfo: TrailBasicInfo?
    private var imageUrls: [TrailMedia]?
    private var drive: TrailDrive?
    private var techRatings: [TechnicalRating]?
    private var comments: [TrailComment]?
    private var commentsCount: Int64 = 0
    private var userData: TrailUserData?
    private var trailDeveloperDetails: TrailDetails? = nil
    private var viewState: ViewState = .description
    private var includeMedia = false
    private var mapImageLoader: MediaLoader?
    private var userLocation: CLLocation?
    private var trailNavigator: ITrailNavigator?
    
    // MARK:- Enums
    private enum ViewState {
        case description
        case pois
        case developer
        case mapimage
        case ugc
    }

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        
        guard let trailId = self.trailId else {
            showError("trailId not set".toError())
            return
        }
        
        let service = ServiceFactory.getTrailService()
        do {
            // Do not continue if trail cannot be found (e.g. after deletion/update)
            guard let trail = try service.getTrailById(trailId) else {
                throw "Could not load trail".toError()
            }
            self.trailBasicInfo = try service.getTrailBasicInfoById(trailId)
            self.trail = trail
            if let drive = try service.getTrailDrives(trailId).first {
                self.drive = drive
                self.trailNavigator = try ServiceFactory.getTrailNavigatorService().getTrailNavigator(trailDrive: drive)
            }
            // User data
            loadTrailUserData()
            // Comments
            try loadTrailComments()
            // Medias as last
            // List trail and point media URls, use thumbnails if possible
            var mediaList = trail.media
            if let mapPoints = trail.navigationInfo?.mapPoints {
                mapPoints.forEach { (point: MapPoint) in
                    mediaList.append(contentsOf: point.media)
                }
            }
            // Images
            imageUrls = mediaList
            try loadTechRatings()
            self.trailUGCRatingView.delegate = self
        } catch {
            showError(error)
            return
        }

        checkLocationPermissions()
        startLocationUpdates()

        getThereButton.imageView?.image = UIImage.getThereImage

        favoriteButton.imageView?.image = UIImage.bookmarkImage

        downloadButton.imageView?.image = UIImage.cacheDownloadImage

        startNavigationButton.imageView?.image = UIImage.startNavigationImage

        TrailInfoDisplay.setDisplayFieldValues(trailTitleLabel: &trailTitleLabel, descriptionTextView: &trailDescriptionTextView, distanceLabel: &trailDistanceLabel, userRatings: &trailUserRatingStar, userRatingCountLabel: &trailUserRatingCountLabel, userRatingValueLabel: &trailRatingValueLabel, difficultyLabel: &difficultyLabel, difficultyView: &difficultyView, basicTrailInfo: trailBasicInfo, trail: trail)

        self.downloadButton.isEnabled = false
        self.downloadButton.alpha = 0

        self.trailImagesCollectionView.register(UINib(nibName: TrailImageCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TrailImageCollectionViewCell.cellIdentifier)

        self.trailDetailsTableView.register(UINib(nibName: WaypointListTableviewCell.cellXibName, bundle: nil), forCellReuseIdentifier: WaypointListTableviewCell.cellIdentifier)

        self.trailUGCCommentsTableView.register(UINib(nibName: CommentTableviewCell.cellXibName, bundle: nil), forCellReuseIdentifier: CommentTableviewCell.cellIdentifier)

        if let trailId = self.trailId {

            self.trailImagesCollectionView.reloadData()

            // Offline map status is asynchronous operation. We are hiding the downloadButton until we
            // successfully retrieve status of the trail cache
            tryOrShowError {
                let status = try OfflineMapManager.shared.getTrailCacheStatus(trailId: trailId)

                // Configure download button

                self.configureDownloadButton(mapStatus: status)
            }
        }
        
        OfflineMapManager.shared.addProgressObserver(observer: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent == self.navigationController?.parent {
            self.delegate?.didTapTrailInfoBackButton()
            print("Back tapped")
        }
    }

    private func downloadTrailOfflineMap(trail: Trail, includeMedia: Bool) {
        self.downloadButton.isEnabled = false
        
        // Download is asynchronous. The callback is called as soon as the download starts.
        
        self.includeMedia = includeMedia
        
        OfflineMapManager.shared.downloadTrailOfflineMap(trailId: trail.info.id, includeImagery: true, downloadTrailMedia: includeMedia) {[weak self] result in
            switch result {
            case .success(_):
                self?.downloadButton.isEnabled = true
                self?.configureDownloadButton(mapStatus: .WAITING)
            case .failure(let error):
                self?.showError(error)
            }
        }
    }

    private func isTrailNavigable() -> Bool {
        guard let location = LocationService.shared.lastReportedLocation, let navigator = self.trailNavigator else {
            return false
        }
        
        do {
            return try navigator.findPossibleNextWayPoints(location: location).count > 0
        }
        catch {
            return false
        }
    }

    // MARK: - Actions
    
    @IBAction func didTapAddComment(_ sender: Any) {
        let alert = UIAlertController(title: "Add Comment", message: "", preferredStyle: .alert)
        var commentTextField: UITextField? = nil
        alert.addTextField { (textField) in
            textField.autocapitalizationType = UITextAutocapitalizationType.sentences
            commentTextField = textField
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action) in
            if let text = commentTextField?.text {
                alert.dismiss(animated: false) {
                    self.postComment(text: text)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // nothing to do
        }))
        present(alert, animated: false, completion: nil)
    }
    
    @IBAction func didTapDownload(_ sender: Any) {
        guard let trail = trail else {
            fatalError("TrailId not set")
        }
        trailId =  trail.info.id
        let handleDownload:((Int64) -> Void) = {[weak self] estimateBytes in
            guard let self = self else { return }
            let estimateText = estimateBytes.humanFileSize()
            
            // For the simplification require always 200 MB of free space
            let mb200: Int64 = 209715200
            let freeBytes: Int64 = OfflineMapManager.shared.getFreeDiskSpace()
            if freeBytes < mb200 {
                AlertUtils.showAlert(viewController: self, title: "Low Space", message: "There is not enough disk space to download the trail")
            } else {
                let alert = UIAlertController(title: "Download", message: "Would you like to download trail map cache (~\(estimateText))?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "With Media", style: .default, handler: {[weak self] action in
                    self?.downloadTrailOfflineMap(trail: trail, includeMedia: true)
                }))
                alert.addAction(UIAlertAction(title: "Without Media", style: .default, handler: {[weak self] action in
                    self?.downloadTrailOfflineMap(trail: trail, includeMedia: false)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        do {
            let trailOfflineMap = try OfflineMapManager.shared.getTrailOfflineMap(trailId: trail.info.id)
            let status = try OfflineMapManager.shared.getTrailCacheStatus(trailId: trail.info.id)
            
            switch status {
            case .NOT_CACHED, .FAILED, .CANCELED:
                // Please note the estimate is often very inaccurate!
                if let size = try? OfflineMapManager.shared.estimateTrailCacheSize(trailId: trail.info.id, includeImagery: true, includeMedia: true).totalSize {
                    handleDownload(size)
                }
            case .COMPLETE:
                
                // For completed cache we show size of the cache with option to delete the cache
                OfflineMapManager.shared.getOfflineMapStorageSize(offlineMapId: trailOfflineMap!.offlineMapId, completion: {[weak self] result in
                    switch result {
                    case .success(let size):
                        let totalSize = size?.totalSize ?? 0

                        guard let self = self else {return}
                        AlertUtils.showPrompt(viewController: self,
                                              title: "Remove Offline Cache?",
                                              message: "The trail is already cached. Cache size: \(Int64(totalSize).humanFileSize()). Do you want to remove the cache?", confirmHandler: {

                            self.downloadButton.isEnabled = false

                            // Delete cache is asynchronous and can take a while for large caches

                            OfflineMapManager.shared.deleteOfflineMap(offlineMapId: trailOfflineMap!.offlineMapId) { error in
                                if let error = error {
                                    self.showError(error)
                                } else {
                                    self.downloadButton.isEnabled = true
                                    self.configureDownloadButton(mapStatus: .NOT_CACHED)
                                }
                            }
                        })
                    case .failure(let error):
                        self?.showError(error)
                    }
                })
            case .WAITING, .IN_PROGRESS, .PAUSED:
                
                // Cache can be waiting in queue or can be downloading.
                // The deleteOfflineCache will either remove it from the queue or cancel the download.
                
                AlertUtils.showPrompt(viewController: self, title: "Cancel Offline Cache?",
                                      message: "Downloading trail cache. Do you want to cancel?", confirmHandler: {
                                        
                                        self.downloadButton.isEnabled = false
                                        
                                        // Delete cache is asynchronous
                                        
                                        OfflineMapManager.shared.deleteOfflineMap(offlineMapId: trailOfflineMap!.offlineMapId) { error in
                                            if let error = error {
                                                self.showError(error)
                                            } else {
                                                self.downloadButton.isEnabled = true
                                                self.configureDownloadButton(mapStatus: .NOT_CACHED)
                                            }
                                        }
                                      })
            @unknown default:
                return
            }
        } catch {
            fatalError("\(error)")
        }
    }
    
    @IBAction func didTapFavorite(_ sender: Any) {
        guard let userData = self.userData else {
            return
        }
        
        guard let trailId = self.trailId else {
            return
        }
        
        // Toggle value
        let toggleFavorite = !(userData.favorite ?? false)
        let service = ServiceFactory.getTrailService()
        service.setTrailFavorite(trailId: trailId, favorite: toggleFavorite) { (result) in
            if case let .success(value) = result {
                // Update the value also in the View
                self.userData = self.userData?.copyWithFavorite(favorite: value.favorite)
                self.favoriteButton.isSelected = toggleFavorite
            } else {
                self.showError("Trail update failed: \(result.buildErrorMessage() ?? "unknown reason")".toError())
            }
        }
    }
    
    @IBAction func didTapGetThere(_ sender: Any) {
    }
    
    @IBAction func didTapStartNavigation(_ sender: Any) {
        let simulateTrailPath = SimulatedTrailPathUtil.isTrailPathSimulated
        guard simulateTrailPath || isTrailNavigable() else {
            AlertUtils.showAlert(viewController: self, title: "Trail lost", message: "You must be closer to the trail path")
            return
        }
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "Driving") as? DrivingViewController {
            vc.title = "Trail Info"
            vc.trailId = self.trailId
            vc.isNavigating = true
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .overCurrentContext
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapTrailDescription() {
        setViewState(.description)
    }
    
    @IBAction func didTapTrailDetails() {
        setViewState(.developer)
    }
    
    @IBAction func didTapTrailMapIMage() {
        setViewState(.mapimage)
    }
    
    @IBAction func didTapTrailUgc() {
        setViewState(.ugc)
    }
    
    @IBAction func didTapTrailPois() {
        setViewState(.pois)
    }
    
    // MARK: - Private methods

    private func postComment(text: String) {
        guard let trailId = self.trailId else {
            return
        }
        let request = PostTrailCommentRequestBuilder.build(trailId: trailId, commentText: text)
        let trailService = ServiceFactory.getTrailService()
        let progressDialog = AlertUtils.buildBlockingProgressValueDialog()!
        progressDialog.style = .loadingIndicator
        progressDialog.title = "Posting Comment"
        self.present(progressDialog, animated: false) {
            trailService.postTrailComment(commentRequest: request) { (result) in
                do {
                    if result.isSuccess {
                        // Let's reload comments
                        try self.loadTrailComments(callback: { (success) in
                            progressDialog.dismiss(animated: false, completion: nil)
                        })
                    } else {
                        throw "Cannot post a comment because of: \(result.errorMessage ?? "unknown error")".toError()
                    }
                } catch {
                    progressDialog.dismiss(animated: false) {
                        self.showError(error)
                    }
                }
            }
        }
    }
    
    private func configureDownloadButton(mapStatus: OfflineMapStatus, progressPercents: Int = 0) {
        self.downloadButton.isEnabled = true
        self.downloadButton.alpha = 1
        
        switch mapStatus {
        case .FAILED, .NOT_CACHED, .PAUSED, .CANCELED:
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
        @unknown default:
            return
        }
    }
    
    private func setViewState(_ newViewState: ViewState) {
        // Prevent Rapid State Changes
        self.view.isUserInteractionEnabled = false
        viewState = newViewState
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.view.isUserInteractionEnabled = true
        }

        self.trailDescriptionButton.isSelected = false
        self.trailDescriptionTextView.isHidden = true
        self.trailUGCView.isHidden = true
        self.trailMapImageView.isHidden = true
        self.trailPoisButton.isSelected = false
        self.trailDetailsButton.isSelected = false
        self.trailDetailsTableView.isHidden = true
        self.trailMapImageButton.isSelected = false
        self.trailUgcButton.isSelected = false
        self.viewState = newViewState
        
        switch newViewState {
        case .description:
            self.trailDescriptionButton.isSelected = true
            self.trailDescriptionTextView.isHidden = false
        case .pois:
            self.trailPoisButton.isSelected = true
            self.trailDetailsTableView.isHidden = false
            self.trailDetailsTableView.reloadData()
        case .developer:
            self.trailDetailsButton.isSelected = true
            self.trailDetailsTableView.isHidden = false
            
            if let trail = self.trail {
                if self.trailDeveloperDetails == nil {
                    self.trailDeveloperDetails = TrailDetails(trail: trail)
                }
            }
            
            self.trailDetailsTableView.reloadData()
        case .mapimage:
            self.trailMapImageButton.isSelected = true
            self.trailMapImageView.isHidden = false

            if let trail = self.trail, self.mapImageLoader == nil {
                // Load map image for the first trail drive
                let service = ServiceFactory.getTrailService()
                if let media = try? service.getTrailDrives(trail.info.id).first?.mapImage {
                    self.mapImageLoader = MediaLoaderFactory.trailMediaLoader(media: media, variant: .DEFAULT)
                    self.trailMapImageView.image = nil

                    self.mapImageLoader?.load(completion: { [weak self] result in
                        if case let .success(value) = result {
                            self?.trailMapImageView.image = value.1
                        }
                    })
                }
            }

        case .ugc:
            self.trailUGCView.isHidden = false
            self.trailUgcButton.isSelected = true
            self.trailUGCCommentsTableView.reloadData()
        }
    }
    
    private func loadTrailUserData() {
        guard let trailId = self.trailId else {
            return
        }
        do {
            let result = try TrailInfoRepo.loadTrailUserData(trailId: trailId)
            self.userData = result
        } catch {
            let reason = error.localizedDescription
            let errorMessage = "Error while loading trail user data: \(trailId), \(reason)"
            Log.e(TAG, errorMessage, error)
            //showError(errorMessage.toError())
        }
        self.favoriteButton.isSelected = self.userData?.favorite ?? false
        self.trailUGCRatingView.rating = self.userData?.rating ?? 0
        let stars: Float = self.userData?.rating ?? 0
        self.trailUGCRatingLabel.text = String(format: "%.1f", stars)
    }
    
    private func loadTechRatings() throws {
        techRatings = try ServiceFactory.getEnumService().getTechRatings()
    }
    
    private func loadTrailComments(callback: ((Bool) -> Void)? = nil) throws {
        guard let trailId = self.trailId else
        {
            callback?(false)
            return
        }
        try TrailInfoRepo.loadTrailComments(trailId: trailId) { [weak self] result in
            guard let self = self else {
                return
            }
            executeBlockOnMainThread {
                if case let .success(value) = result {
                    self.comments = value.comments
                    self.commentsCount = value.paging.total
                    callback?(true)
                } else {
                    let reason = result.buildErrorMessage() ?? "unknown reason"
                    let errorMessage = "Error while loading trail comments: \(trailId), \(reason)"
                    Log.e(self.TAG, errorMessage, result.error)
                    //self.showError(errorMessage.toError())
                    callback?(false)
                    return
                }
                self.trailUGCCommentsLabel.text = "\(self.commentsCount) comments"
                self.trailUGCCommentsTableView.reloadData()
            }
        }
    }
}

// MARK: - Table Extensions

extension TrailInfoViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == trailDetailsTableView {
            switch viewState {
            case .developer: return 15
            case .pois: return 1
            default: return 0
            }
        } else if tableView == trailUGCCommentsTableView {
            return viewState == .ugc ? 1 : 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.viewState {
        case .developer:
            return 50
        case .pois:
            if let waypoint = self.drive?.waypoints[indexPath.row], let text = waypoint.description {
                return WaypointListTableviewCell.getEstimatedHeightInTable(table: tableView, text: text)
            } else {
                return 0
            }
        case .ugc:
            if let comment = self.comments?[indexPath.row] {
                return CommentTableviewCell.getEstimatedHeightInTable(table: tableView, text: comment.text)
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.viewState {
        case .developer:
            return 50
        case .pois:
            if let waypoint = self.drive?.waypoints[indexPath.row], let text = waypoint.description {
                return WaypointListTableviewCell.getEstimatedHeightInTable(table: tableView, text: text)
            } else {
                return 0
            }
        case .ugc:
            if let comment = self.comments?[indexPath.row] {
                return CommentTableviewCell.getEstimatedHeightInTable(table: tableView, text: comment.text)
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == trailDetailsTableView {
            switch self.viewState {
            case .developer:
                guard let trailDetails = self.trailDeveloperDetails else {
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
            case .pois:
                guard let waypoints = self.drive?.waypoints else {
                    return 0
                }
                return waypoints.count
            default:
                return 0
            }
        } else if tableView == trailUGCCommentsTableView {
            if viewState == .ugc {
                return Int(commentsCount)
            }
            return 0
        }
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch self.viewState {
        case .developer:
            if let trailDetails = self.trailDeveloperDetails, let section = trailDetails.getSection(sectionId: section) {
                return section.name
            } else {
                return ""
            }
        case .pois:
            return "Waypoints"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == trailDetailsTableView {
            switch self.viewState {
            case .developer:
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

                if let trailDetails = self.trailDeveloperDetails, let section = trailDetails.getSection(sectionId: indexPath.section) {
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
            case .pois:
                let cell :WaypointListTableviewCell = tableView.dequeueReusableCell(withIdentifier: WaypointListTableviewCell.cellIdentifier, for: indexPath) as! WaypointListTableviewCell

                let waypoint = self.drive?.waypoints[indexPath.row]

                if let poiDistance = waypoint?.distanceMarker {
                    cell.poiListItemMillage.text = DistanceFormatter.formatDistance(distanceInMeters: poiDistance)
                } else {
                    cell.poiListItemMillage.text = "N/A"
                }

                cell.poiDescriptionLabel.text = waypoint?.description

                if let waypoint = waypoint {
                    if let name = waypoint.point.name, !name.isEmpty {
                        cell.poiListItemName.text = name
                    } else {
                        cell.poiListItemName.text = "WP #\(waypoint.navigationOrder)"
                    }
                } else {
                    cell.poiListItemName.text = ""
                }

                cell.delegate = self
                return cell
            default:
                return UITableViewCell()
            }
        } else if tableView == trailUGCCommentsTableView {
            if viewState == .ugc {
                let cell: CommentTableviewCell = tableView.dequeueReusableCell(withIdentifier: CommentTableviewCell.cellIdentifier, for: indexPath) as! CommentTableviewCell
                if let comment = self.comments?[indexPath.row]{
                    cell.userNameLabel.text = comment.user.userId
                    cell.commentTextLabel.text = comment.text
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch self.viewState {
        case .developer:
            if let trailDetails = self.trailDeveloperDetails, let section = trailDetails.getSection(sectionId: indexPath.section) {
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
        case .pois:
            break
        default:
            break
        }
        return nil
    }
}

// MARK: - Offline Cache extension
extension TrailInfoViewController : CacheProgressDelegate {
    func onProgressChanged(offlineMap: IOfflineMap) {
        if let trailOfflineMap = offlineMap as? ITrailOfflineMap, trailOfflineMap.trailId == self.trailId {
            configureDownloadButton(mapStatus: .IN_PROGRESS, progressPercents: Int(offlineMap.progress * 100))
        }
    }
    
    func onError(error: [OfflineResourceError], offlineMap: IOfflineMap) {
        if let trailOfflineMap = offlineMap as? ITrailOfflineMap, trailOfflineMap.trailId == self.trailId {
            let message = error.map ({ (resourceError) -> String in
                return "\(resourceError.offlineResource.getResourceTypeName()) failed \(resourceError.error)"
            }).joined(separator: "\n")
            showError(message.toError())
            configureDownloadButton(mapStatus: .FAILED)
        }
    }
    
    func onComplete(offlineMap: IOfflineMap) {
        if let trailOfflineMap = offlineMap as? ITrailOfflineMap, trailOfflineMap.trailId == self.trailId {
            configureDownloadButton(mapStatus: .COMPLETE)
        }
    }
    
    func onImageryDeleted(offlineMaps: [IOfflineMap]) {
        // We do not want to do anything here
    }
}

// MARK: - Collection view extensions

extension TrailInfoViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageUrls?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrailImageCollectionViewCell.cellIdentifier, for: indexPath) as! TrailImageCollectionViewCell
        if let trailMediaArray = self.imageUrls {
            cell.bindView(media: trailMediaArray[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let media = self.imageUrls?[indexPath.row] {
            if let vc = UIStoryboard(name: "Main", bundle: nil) .
                instantiateViewController(withIdentifier: "PhotoViewController") as? PhotoViewController {
                vc.mediaLoader = MediaLoaderFactory.trailMediaLoader(media: media, variant: .DEFAULT) 
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

// MARK: - Waypoint List extension

extension TrailInfoViewController : WaypointListViewDelegate {
    func didSelectWayPoint(wayPoint: TrailDriveWaypoint) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "TrailPoiDetailVC") as? TrailPoiDetailViewController {
            vc.trailDriveWaypoint = wayPoint
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func didPressDetailButton(cell: WaypointListTableviewCell) {
        if let index = trailDetailsTableView.indexPath(for: cell), let waypoint = drive?.waypoints[index.row] {
            didSelectWayPoint(wayPoint: waypoint)
        }
    }
}

// MARK: - Interactive rating extension

extension TrailInfoViewController : RatingViewDelegate {
    func ratingView(_ ratingView: RatingView, didChangeRating newRating: Float) {
        guard self.userData != nil else {
            return
        }
        
        guard let trailId = self.trailId else {
            return
        }
        
        let service = ServiceFactory.getTrailService()
        service.setTrailRating(trailId: trailId, rating: Double(newRating), completion: { result in
            if result.isSuccess {
                // Update the value also in the View
                self.userData = self.userData?.copyWithRating(rating: newRating)
            } else {
                self.showError("Trail update failed: \(result.buildErrorMessage() ?? "unknown reason")".toError())
            }
        })
    }
}
