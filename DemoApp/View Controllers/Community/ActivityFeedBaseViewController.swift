//
//  ActivityFeedBaseViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 10.01.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import ObjectMapper

class ActivityFeedBaseViewController: BaseViewController {

    // MARK:- Properties
    var refreshControl = UIRefreshControl()
    var listItems: [ActivityFeedItem]? = nil
    var canRefresh = true
    // MARK:- Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadTrips(forceReload: false)
    }
    
    @objc private func refresh(sender:AnyObject) {
        loadTrips(forceReload: true)
    }

    // MARK:- Loaders
    func loadTrips(forceReload: Bool) {
        reloadTableData()
    }

    func reloadTableData() {
        self.refreshControl.endRefreshing()
        self.tableView.reloadData()
    }

    func convertToFeedItem(trips: [ActivityFeedEntry]) -> [ActivityFeedItem] {
        var items = [ActivityFeedItem]()
        for trip in trips {
            items.append(ActivityFeedTripUserItem(data: trip))
            items.append(ActivityFeedTripHeaderItem(info: trip))
            items.append(ActivityFeedTripStatisticsItem(info: trip))
            items.append(ActivityFeedTripThumbnailItem(data: trip))
            items.append(ActivityFeedTripUgcFooterItem(data: trip))
        }
        return items
    }
}

// MARK:- Table extensions
extension ActivityFeedBaseViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = listItems?.count {
            if count == 0 && !refreshControl.isRefreshing {
                return 1
            } else {
                return count
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let items = self.listItems, items.count > 0 else {
            return 80
        }
        let item = items[indexPath.row]
        switch item.type {
        case .ONLINE_TRIP_HEADER:
            return ActivityFeedTripHeaderViewCell.getEstimatedHeight(item: item as! ActivityFeedTripHeaderItem, table: tableView)
        case .ONLINE_TRIP_STATISTICS:
            return 60
        case .ONLINE_TRIP_THUMBNAIL:
            return 220
        case .ONLINE_TRIP_USER:
            return 80
        case .ONLINE_TRIP_UGC_FOOTER:
            return 40
        case .LOCAL_RECORDED_TRIP:
            return ActivityFeedRecordedTripViewCell.getEstimatedHeight(recording: (item as! ActivityFeedRecordedTripItem).data!, table: tableView)
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let items = self.listItems, items.count > 0 else {
            return nil
        }
        let item = items[indexPath.row]
        switch item.type {
        case .LOCAL_RECORDED_TRIP:
            guard let recording = (item as? ActivityFeedRecordedTripItem)?.data else {
                return nil
            }
            
            // We need to load full trip and the `custom data` to distinguish
            // between free roam and trail collection recordings
            var isTrailCollection = false
            do {
                isTrailCollection = (try getTrailCollectionData(uuid: recording.uuid)) != nil
            } catch {
                showError(error)
                return nil
            }
            
            switch recording.status {
            case .RECORDING, .PAUSED:
                if isTrailCollection {
                    // Navigate to Free Roam recording activity
                    self.openTrailCollectionViewController()
                } else {
                    // Navigate to Trail Collection recording activity
                    self.openRecordNewTripViewController()
                }
            case .FINISHED:
                if isTrailCollection {
                    // Navigate to the SAVE activity in case of finished trail collection
                    self.openSaveTrailCollectionViewController(tripUuid: recording.uuid, completion: nil)
                } else {
                    // Navigate to the SAVE activity in case of finished recording
                    self.openSaveTripViewController(tripUuid: recording.uuid, completion: nil)
                }
            case .QUEUED, .UPLOADED:
                self.openSaveTripViewController(tripUuid: recording.uuid, completion: nil)
            default:
                break
            }
        default:
            showTripDetailsViewController(tripUuid: item.tripUUID)
        }
        return nil
    }
    
    private func getTrailCollectionData(uuid: String) throws -> TrailCollectionData? {
        let service = ServiceFactory.getTripRecordingService()
        let tripRecording = try service.getTripRecordingByUUID(uuid: uuid)
        
        if let json = tripRecording?.extProperties.first?.data {
            return Mapper<TrailCollectionData>().map(JSONString: json)
        } else {
            return nil
        }
    }
    
    private func openRecordNewTripViewController() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "RecordNewTripVC") as? RecordNewTripViewController {
            vc.title = "Record New Free Roam Trip"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func openTrailCollectionViewController() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "TrailCollectionVC") as? TrailCollectionViewController {
            vc.title = "Trail Collection Mode"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func openSaveTripViewController(tripUuid: String, completion: (() -> Void)?) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "SaveTripVC") as? SaveTripViewController {
            vc.tripUuid = tripUuid
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: completion)
        }
    }
    
    private func openSaveTrailCollectionViewController(tripUuid: String, completion: (() -> Void)?) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "TrailSaveVC") as? TrailSaveViewController {
            vc.tripUuid = tripUuid
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: completion)
        }
    }
    
    private func showTripDetailsViewController(tripUuid: String, viewState: OnlineTripViewController.ViewState? = nil) {
        if let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "OnlineTripViewVC") as? OnlineTripViewController {
            vc.tripUuid = tripUuid
            vc.initialViewState = viewState
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableView(tableView, estimatedHeightForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let items = self.listItems, items.count > 0 else {
            return
        }
        let item = items[indexPath.row]
        guard item.type == .LOCAL_RECORDED_TRIP else {
            return
        }
        guard let recording = (item as? ActivityFeedRecordedTripItem)?.data, (recording.status == .UPLOADED || recording.status == .QUEUED) else {
            return
        }
        
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "uploadVC") as? UploadViewController {
            vc.tripUuid = recording.uuid
            vc.versionUUid = recording.versionUuid
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let items = self.listItems, items.count > 0 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityFeedNoRecordsViewCell") as! ActivityFeedNoRecordsViewCell
            return cell
        }
        let item = items[indexPath.row]
        switch item.type {
        case .ONLINE_TRIP_HEADER:
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityFeedTripHeaderViewCell") as! ActivityFeedTripHeaderViewCell
            cell.bindView(item: item as! ActivityFeedTripHeaderItem)
            return cell
        case .ONLINE_TRIP_STATISTICS:
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityFeedTripStatisticsViewCell") as! ActivityFeedTripStatisticsViewCell
            cell.bindView(item: item as! ActivityFeedTripStatisticsItem)
            return cell
        case .ONLINE_TRIP_THUMBNAIL:
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityFeedTripThumbnailViewCell") as! ActivityFeedTripThumbnailViewCell
            cell.bindView(item: item as! ActivityFeedTripThumbnailItem)
            return cell
        case .ONLINE_TRIP_USER:
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityFeedTripUserViewCell") as! ActivityFeedTripUserViewCell
            cell.bindView(item: item as! ActivityFeedTripUserItem)
            return cell
        case .ONLINE_TRIP_UGC_FOOTER:
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityFeedTripUgcFooterCell") as! ActivityFeedTripUgcFooterCell
            cell.delegate = self
            cell.bindView(item: item as! ActivityFeedTripUgcFooterItem)
            return cell
        case .LOCAL_RECORDED_TRIP:
            let cell: ActivityFeedRecordedTripViewCell = tableView.dequeueReusableCell(withIdentifier: "activityFeedRecordedTripViewCell", for: indexPath) as! ActivityFeedRecordedTripViewCell
            cell.accessoryType = .none
            if let recording = (item as? ActivityFeedRecordedTripItem)?.data {
                cell.bindView(recording: recording)
                if recording.status == .QUEUED || recording.status == .UPLOADED {
                    cell.accessoryType = .detailButton
                }
            }
            return cell
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -100 { //change 100 to whatever you want
            if canRefresh && !self.refreshControl.isRefreshing {
                self.canRefresh = false
                self.refreshControl.beginRefreshing()
                self.refresh(sender: scrollView)
            }
        } else if scrollView.contentOffset.y >= 0 {
            self.canRefresh = true
        }
    }
    
    /// Update the model and UI for trip `likes`
    private func onLikesChanged(likesResult: SetTripLikedResult) {
        // Change the "likes" value
        guard let item = listItems?.first(where: { (it) -> Bool in
            return it.tripUUID == likesResult.tripUuid && it.type == .ONLINE_TRIP_UGC_FOOTER
        }), let footerItem = item as? ActivityFeedTripUgcFooterItem else {
            return
        }
        
        guard let tripCopy = footerItem.data?.trip.copy(userLike: likesResult.userLike, likesCount: likesResult.likes) else {
            return
        }
        
        footerItem.data?.trip = tripCopy
        // Notify about the change
        tableView.reloadData()
    }
}

// MARK:- ActivityFeedTripUgcFooterCellDelegate extension
extension ActivityFeedBaseViewController : ActivityFeedTripUgcFooterCellDelegate {
    func onLikeClicked(item: ActivityFeedItem) {
        if item.type == .ONLINE_TRIP_UGC_FOOTER {
           let service = ServiceFactory.getTripService()
            
            guard let dialog = AlertUtils.buildBlockingProgressValueDialog(), let footerItem = item as? ActivityFeedTripUgcFooterItem else {
                return
            }
            dialog.title = "Updating Trip"
            dialog.style = .loadingIndicator
            self.present(dialog, animated: false, completion: nil)
         
            let liked = !(footerItem.data?.trip.userLike ?? false)
            service.setTripLiked(tripUuid: item.tripUUID, liked: liked) { (result) in
                dialog.dismiss(animated: false, completion: nil)
                if result.isSuccess {
                    if let likesResult = result.value {
                        self.onLikesChanged(likesResult: likesResult)
                    }
                } else {
                    self.showError((result.buildErrorMessage() ?? "unknown error").toError())
                }
            }
        }
    }
    
    func onPhotosClicked(item: ActivityFeedItem) {
        showTripDetailsViewController(tripUuid: item.tripUUID, viewState: .photos)
    }
}
