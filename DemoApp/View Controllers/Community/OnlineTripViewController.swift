//
//  OnlineTripViewController.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 6/3/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import StarryStars
import CoreLocation

class OnlineTripViewController: UIViewController {

    // MARK:- Enums
    enum ViewState {
        case map
        case photos
        case info
        case pois
        case statistics
    }

    // MARK:- Properties
    private var viewState: ViewState = .map
    private let TAG = "OnlineTripViewController"
    private var mapLoaded = false
    private var currentStyle = AccuTerraStyle.vectorStyleURL
    private lazy var statistics = [(String, String)]()
    var initialViewState: ViewState?
    var tripUuid: String?
    private var trip: Trip?
    private var userData: SetTripLikedResult?
    private lazy var tripMedia = [TripMedia]()
    private lazy var comments = [TripComment]()
    private var isCurrentUserTrip: Bool {
        let tripUserUuid = self.trip?.userInfo.driverId
        let currentUserUuid = DemoIdentityManager.shared.getUserId()
        return currentUserUuid == tripUserUuid
    }

    // MARK:- Outlets
    @IBOutlet weak var userAvatarImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tripDateLabel: UILabel!
    @IBOutlet weak var tripNameLabel: UILabel!
    @IBOutlet weak var tripLocationLabel: UILabel!
    @IBOutlet weak var tripRelatedTrailLabel: UILabel!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var poisButton: UIButton!
    @IBOutlet weak var statisticsButton: UIButton!
    @IBOutlet weak var tripDescriptionLabel: UILabel!
    @IBOutlet weak var tripCommentsLabel: UILabel!
    @IBOutlet weak var tripLikesLabel: UILabel!
    @IBOutlet weak var tripLikeIcon: UIImageView!
    @IBOutlet weak var tripCommentsTableView: UITableView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var contentTableView: UITableView!
    // Map Content
    @IBOutlet weak var accuTerraMapView: AccuTerraMapView!
    // Photos Content
    @IBOutlet weak var tripPhotoCollection: UICollectionView!
    // Info Content
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var sharingStatusLabel: UILabel!
    @IBOutlet weak var ratingStars: RatingView!
    @IBOutlet weak var promotedImageView: UIImageView!

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Trip"
        self.tripPhotoCollection.register(UINib(nibName: TripMediaCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TripMediaCollectionViewCell.cellIdentifier)
        self.loadingView.isHidden = false
        self.mapButton.isSelected = true
        userAvatarImageView.layer.cornerRadius = userAvatarImageView.frame.width / 2.0
        loadTrip()
        loadTripComments()
        setupMap()
        if let initialViewState = self.initialViewState {
            setViewState(initialViewState)
        }
    }
    
    private func setViewState(_ newViewState: ViewState) {
        let buttons: [UIButton] = [mapButton, photosButton, infoButton, poisButton, statisticsButton]
        var selectedButton: UIButton? = nil
        self.accuTerraMapView.isHidden = true
        self.tripPhotoCollection.isHidden = true
        self.infoView.isHidden = true
        self.contentTableView.isHidden = true
        
        self.viewState = newViewState
        
        switch newViewState {
        case .map:
            selectedButton = mapButton
            self.accuTerraMapView.isHidden = false
        case .photos:
            selectedButton = photosButton
            self.tripPhotoCollection.isHidden = false
            self.tripPhotoCollection.reloadData()
        case .info:
            selectedButton = infoButton
            infoView.isHidden = false
        case .pois:
            selectedButton = poisButton
            self.contentTableView.isHidden = false
            self.contentTableView.reloadData()
        case .statistics:
            selectedButton = statisticsButton
            self.contentTableView.isHidden = false
            self.contentTableView.reloadData()
        }
        
        buttons.forEach { (it) in
            it.isSelected = it == selectedButton
        }
    }

    // MARK:- Loaders
    private func loadTrip() {
        guard let tripUuid = self.tripUuid else {
            return
        }
        
        let service = ServiceFactory.getTripService()
        service.getTrip(tripUuid: tripUuid, completion: { result in
            self.loadingView.isHidden = true
            switch result {
            case .success(let value):
                self.trip = value
                self.userData = SetTripLikedResult(tripUuid: self.trip!.info.uuid, userLike: self.trip!.userInfo.userLike ?? false, likes: self.trip!.likesCount)
                self.fillTripData()
                self.setUpNavBar()
                self.zoomToTrip(trip: self.trip!)
                
                // setup trip media
                // We do merge trip photos with POI photos to show everything together
                let poiMedia = self.trip!.navigation.points.flatMap { point in
                    point.media.map { media in media }
                }
                self.tripMedia = self.trip!.media + poiMedia
                self.tripPhotoCollection.reloadData()
            case .failure(_):
                let errorMessage = "Error while loading trip: \(tripUuid), \(result.buildErrorMessage() ?? "unknown")}"
                self.showError(errorMessage.toError())
            }
        })
    }
    
    private func loadTripComments() {
        guard let tripUuid = self.tripUuid else {
            return
        }
        do {
            let service = ServiceFactory.getTripService()
            let criteria = try GetTripCommentsCriteriaBuilder.build(tripUuid: tripUuid)
            service.getTripComments(criteria: criteria) { result in
                switch result {
                case .success(let value):
                    self.comments = value.comments
                    self.tripCommentsTableView.reloadData()
                case .failure(_):
                    let errorMessage = "Error while loading trip comments: \(tripUuid), \(result.buildErrorMessage() ?? "unknown")"
                    self.showError(errorMessage.toError())
                }
            }
        } catch {
            showError(error)
        }
    }

    // MARK:- UI
    private func fillTripData() {
        guard let trip = self.trip else {
            return
        }
        // Header
        userNameLabel.text = trip.userInfo.driverId
        tripDateLabel.text = trip.info.tripStart.toLocalDateTimeString()
        
        // Name + Location
        tripNameLabel.text = trip.info.name
        let locationString = trip.location.getLocationLabelString()
        tripLocationLabel.text = locationString
        
        // Related trail name
        if let trailId = trip.info.trailId {
            let service = ServiceFactory.getTrailService()
            if let trailBasicInfo = try? service.getTrailBasicInfoById(trailId) {
                tripRelatedTrailLabel.text = "Trail: \(trailBasicInfo.name)"
                tripRelatedTrailLabel.isHidden = false
            }
        } else {
            tripRelatedTrailLabel.isHidden = true
        }
        // Description
        tripDescriptionLabel.text = trip.info.description
        // Comments
        tripCommentsLabel.text = "\(trip.commentsCount) Comments"
        
        if let userData = self.userData {
            tripLikesLabel.text = "\(userData.likes) Likes"
            tripLikeIcon.tintColor = userData.userLike ? UIColor.Active : UIColor.Inactive
        }
        
        // Info
        
        self.sharingStatusLabel.text = trip.userInfo.sharingType.getName()
        if let rating = trip.userInfo.userRating {
            ratingStars.rating = Float(rating)
        }
        promotedImageView.image = UIImage(named: trip.userInfo.promoteToTrail ? "checkmark.square.fill" : "checkmark.square")
        
        // Statistics
        
        statistics.removeAll()
        statistics.append(("Length", DistanceFormatter.formatDistance(distanceInMeters: trip.statistics.length)))
        statistics.append(("Driving Time", DrivingTimeFormatter.formatDrivingTime(ctimeInSeconds: trip.statistics.drivingTime)))
        statistics.append(("Cumulative Ascent", DistanceFormatter.formatDistance(distanceInMeters: trip.statistics.cumulativeAscent)))
        statistics.append(("Cumulative Descent", DistanceFormatter.formatDistance(distanceInMeters: trip.statistics.cumulativeDescent)))
        if let minElevation = trip.statistics.minElevation {
            statistics.append(("Min Elevation", DistanceFormatter.formatDistance(distanceInMeters: minElevation)))
        } else {
            statistics.append(("Min Elevation", "n/a"))
        }
        if let maxElevation = trip.statistics.maxElevation {
            statistics.append(("Max Elevation", DistanceFormatter.formatDistance(distanceInMeters: maxElevation)))
        } else {
            statistics.append(("Max Elevation", "n/a"))
        }
        if let avgSpeed = trip.statistics.avgSpeed {
            statistics.append(("Avg Speed", SpeedFormatter.formatSpeed(speedInMetersPerSecond: Double(avgSpeed))))
        } else {
            statistics.append(("Avg Speed", "n/a"))
        }
        if let maxSpeed = trip.statistics.maxSpeed {
            statistics.append(("Max Speed", SpeedFormatter.formatSpeed(speedInMetersPerSecond: Double(maxSpeed))))
        } else {
            statistics.append(("Max Speed", "n/a"))
        }
    }

    func setUpNavBar() {
        if self.isCurrentUserTrip {
            // Right button
            let actionButton = UIBarButtonItem(title: "≡", style: .done, target: self, action: #selector(self.buttonActionTapped))
            self.navigationItem.rightBarButtonItem = actionButton
        }
    }
    
    private func updateTripCommentsCount(commentsCount: Int?) {
        guard let commentsCount = commentsCount, let trip = self.trip else {
            return
        }
        // Check if there was a change and propagate it
        if trip.commentsCount != commentsCount {
            let newTrip = trip.copy(commentsCount: commentsCount)
            self.trip = newTrip
            self.fillTripData()
        }
    }

    // MARK:- Actions and IBActions
    @IBAction func onMapClicked() {
        setViewState(.map)
    }
    
    @IBAction func onInfoClicked() {
        setViewState(.info)
    }
    
    @IBAction func onPhotosClicked() {
        setViewState(.photos)
    }
    
    @IBAction func onPoisClicked() {
        setViewState(.pois)
    }
    
    @IBAction func onStatisticsClicked() {
        setViewState(.statistics)
    }
    
    @IBAction func onAddCommentIconClicked() {
        guard let tripUuid = self.tripUuid else {
            return
        }
        
        // Build and display `Add Comment` dialog
        if let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "NewCommentVC") as? NewCommentViewController {
            vc.tripUuid = tripUuid
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc private func buttonActionTapped() {
        let options = UIAlertController(title: "Trip", message: nil, preferredStyle: .actionSheet)
        
        options.addAction(UIAlertAction(title: "Promote to Trail", style: .default, handler: { (action) in
            self.onPromoteTrip()
        }))
        options.addAction(UIAlertAction(title: "Edit Trip", style: .default, handler: { (action) in
            self.editTrip()
        }))
        options.addAction(UIAlertAction(title: "Delete Trip", style: .destructive, handler: { (action) in
            self.onDeleteTrip()
        }))
       
        options.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(options, animated: false)
    }

    // MARK:- Promote
    private func onPromoteTrip() {
        guard let tripName = self.trip?.info.name else {
            return
        }
        AlertUtils.showPrompt(viewController: self, title: "Promote Trip?", message: "Do you really want to promote \(tripName)?") {
            self.promoteTrip()
        } cancelHandler: {
        }
    }
    
    private func promoteTrip() {
        guard let tripUuid = self.trip?.info.uuid, let dialog = AlertUtils.buildBlockingProgressValueDialog() else {
            return
        }
        
        dialog.title = "Promoting Trip"
        dialog.style = .loadingIndicator
        
        self.present(dialog, animated: false)

        let service = ServiceFactory.getTripService()
        service.promoteTripToTrail(tripUuid: tripUuid, completion: { result in
            dialog.dismiss(animated: false, completion: nil)
            switch result {
            case .success(let value):
                self.showInfo("Trip trip was promoted to state: \(value.promotionState.getName())")
            case .failure(_):
                self.showError((result.buildErrorMessage() ?? "Unknown error").toError())
            }
        })
    }

    // MARK:- Delete
    private func onDeleteTrip() {
        guard let tripName = self.trip?.info.name else {
            return
        }
        AlertUtils.showPrompt(viewController: self, title: "Delete Trip?", message: "Do you really want to delete \(tripName)?") {
            self.deleteTrip()
        } cancelHandler: {
        }
    }
    
    // MARK:- Edit
    private func editTrip() {
        guard let trip = trip else {
            return
        }
        
        do {
            let _ = try ServiceFactory.getTripRecordingService().startTripEditing(trip: trip)
            showTripEditVC(tripUuid: trip.info.uuid)
        }
        catch {
            showError(error)
        }
    }
    
    private func showTripEditVC(tripUuid: String) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "SaveTripVC") as? SaveTripViewController {
            vc.tripUuid = tripUuid
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
    }
    
    private func deleteTrip() {
        guard let tripUuid = self.trip?.info.uuid, let dialog = AlertUtils.buildBlockingProgressValueDialog() else {
            return
        }
        
        dialog.title = "Deleting Trip"
        dialog.style = .loadingIndicator
        
        self.present(dialog, animated: false)

        let service = ServiceFactory.getTripService()
        service.deleteTrip(tripUuid: tripUuid, completion: { result in
            dialog.dismiss(animated: false, completion: nil)
            if (result.isSuccess) {
                // Close the screen
                self.navigationController?.popViewController(animated: true)
            } else {
                self.showError((result.buildErrorMessage() ?? "Unknown error").toError())
            }
        })
    }
}

// MARK:- UITableView extension
extension OnlineTripViewController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableView(tableView, heightForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.tripCommentsTableView {
            let item = self.comments[indexPath.row]
            return OnlineTripCommentViewCell.getEstimatedHeight(item: item, table: tableView)
        } else {
            switch self.viewState {
            case .pois:
                let item = trip!.navigation.points[indexPath.row]
                return OnlineTripPoiViewCell.getEstimatedHeight(tripPoint: item, table: tableView)
            case .statistics:
                return 40
            default:
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tripCommentsTableView {
            return self.comments.count
        } else {
            switch self.viewState {
            case .pois:
                return self.trip?.navigation.points.count ?? 0
            case .statistics:
                return self.statistics.count
            default:
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tripCommentsTableView {
            let item = self.comments[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "onlineTripCommentViewCell") as! OnlineTripCommentViewCell
            cell.bindView(item: item)
            return cell
        } else {
            switch self.viewState {
            case .pois:
                let item = self.trip!.navigation.points[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "onlineTripPoiViewCell") as! OnlineTripPoiViewCell
                cell.bindView(tripPoint: item)
                return cell
            case .statistics:
                let item = self.statistics[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "onlineTripStatisticViewCell") as! OnlineTripStatisticViewCell
                cell.bindView(name: item.0, value: item.1)
                return cell
            default:
                return UITableViewCell()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView == self.tripCommentsTableView {
            // nothing to do
        } else {
            switch self.viewState {
            case .pois:
                guard let item = self.trip?.navigation.points[indexPath.row] else {
                    return nil
                }
                if let vc = UIStoryboard(name: "Main", bundle: nil) .
                    instantiateViewController(withIdentifier: "OnlineTripPoiVC") as? OnlineTripPoiViewController {
                    vc.tripPoint = item
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            default:
                // nothing to do
                break
            }
        }
        return nil
    }
}

// MARK:- NewCommentViewControllerDelegate extension
extension OnlineTripViewController : NewCommentViewControllerDelegate {
    func didAddNewComment(commentsCount: Int?) {
        // Let's reload comments
        self.loadTripComments()
        self.updateTripCommentsCount(commentsCount: commentsCount)
    }
}

// MARK:- AccuTerraMapViewDelegate extension
extension OnlineTripViewController : AccuTerraMapViewDelegate {

    func onMapLoadFailed(error: Error) {
        showError(error)
    }

    func onStyleChangeFailed(error: Error) {
        showError(error)
    }
    
    func didTapOnMap(coordinate: CLLocationCoordinate2D) {
        // nothing to do
    }
    
    func onMapLoaded() {
        self.mapLoaded = true
        
        guard let trip = self.trip else {
            return
        }
        
        zoomToTrip(trip: trip)
    }
    
    private func zoomToTrip(trip: Trip) {
        guard mapLoaded else {
            return
        }
        do {
            // Avoid map rotation by user
            accuTerraMapView.isRotateEnabled = false
            
            // Add trip layers to the map
            try accuTerraMapView.tripLayersManager.addStandardTripLayers()
            // Load trip data into the UI
            // Load trip into the map
            self.addTripToMap(trip: trip)
            // Zoom to path area
            if let mapBounds = trip.location.mapBounds {
                accuTerraMapView.zoomToBounds(targetBounds: mapBounds)
            }
        } catch {
            showError(error)
        }
    }
    
    private func addTripToMap(trip: Trip) {
        let tripLayersManager = accuTerraMapView.tripLayersManager
        let tripUuid = trip.info.uuid
        let path = trip.navigation.path.geometryGeoJSON
        let points = trip.navigation.points
        do {
            try tripLayersManager.setVisibleTrip(tripUuid: tripUuid, pathGeoJson: path, points: points)
        } catch {
            showError(error)
        }
    }
    
    func onStyleChanged() {
        // nothing to do
    }
    
    func onSignificantMapBoundsChange() {
        // nothing to do
    }
    
    func onTrackingModeChanged(mode: TrackingOption) {
        // nothing to do
    }
    
    private func setupMap() {
        self.accuTerraMapView.initialize(styleURL: self.currentStyle)
    }
}

// MARK:- UICollectionView extension
extension OnlineTripViewController : UICollectionViewDelegate, UICollectionViewDataSource, TripMediaCollectionViewCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let media = self.tripMedia[indexPath.row]
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "PhotoViewController") as? PhotoViewController {
            vc.mediaLoader = MediaLoaderFactory.tripMediaLoader(media: media, variant: .DEFAULT) 
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tripMediaDeletePressed(media: TripMedia) {
        // not supported in this controller
    }
    
    func canEditMedia() -> Bool {
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tripMedia.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TripMediaCollectionViewCell.cellIdentifier, for: indexPath) as! TripMediaCollectionViewCell
        cell.bindView(media: self.tripMedia[indexPath.row], mediaVariant: .THUMBNAIL, delegate: self)
        return cell
    }
}
