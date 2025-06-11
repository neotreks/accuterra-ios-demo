//
//  MyTripsViewController.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 5/18/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import SSZipArchive
import Reachability
import Combine

class MyTripsViewController: ActivityFeedBaseViewController {

    // MARK:- Outlets
    @IBOutlet weak var sourceSwitch: UISwitch!

    // MARK:- Properties
    private let TAG = LogTag(subsystem: "ATDemoApp", category: "MyTripsViewController")
    private var cancellableRefs = [AnyCancellable]()
    private var requiresReload = false
    private var reloadTimer: Timer?
    var tripService: ITripRecordingService?

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default
            .publisher(for: TripUploadNotificationName)
            .receive(on: DispatchQueue.main)
            .sink() { [weak self] notification in
                self?.onTripUploadStatusChanged(notification: notification)
            }
            .store(in: &cancellableRefs)
        
        NotificationCenter.default
            .publisher(for: TripRecordingStatusChangeNotification.name)
            .receive(on: DispatchQueue.main)
            .sink() { [weak self] notification in
                self?.onTripUploadStatusChanged(notification: notification)
            }
            .store(in: &cancellableRefs)

        NotificationCenter.default.publisher(for: .userChanged)
            .sink { [weak self] _ in
                self?.loadTrips(forceReload: true)
            }.store(in: &cancellableRefs)

        reloadTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(reloadTripsOnTimer), userInfo: nil, repeats: true)
        self.loadTrips(forceReload: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavBar()
    }

    deinit {
        reloadTimer?.invalidate()
    }
    
    // MARK:- IBActions
    @IBAction func sourceSwitchValueChanged() {
        self.loadTrips(forceReload: true)
    }

    // MARK:- Actions
    @objc func buttonAddTapped() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "RecordNewTripChooseVC") as? RecordNewTripChooseViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func reloadTripsOnTimer() {
        if sourceSwitch.isOn && requiresReload {
            self.loadTrips(forceReload: true)
            requiresReload = false
        }
    }

    // MARK:- Loaders
    override func loadTrips(forceReload: Bool) {
        self.sourceSwitch.isEnabled = false
        self.refreshControl.beginRefreshing()
        if sourceSwitch.isOn {
            self.listItems?.removeAll()
            self.tableView.reloadData()
            do {
                let criteria = TripRecordingSearchCriteria()
                try self.loadRecordedTrips(criteria: criteria)
            } catch {
                self.listItems = [ActivityFeedItem]()
                showError(error)
            }
            refreshControl.endRefreshing()
            self.sourceSwitch.isEnabled = true
            reloadTableData()
        } else {
            if NetworkUtils.shared.isOnline() {
                // Check if not already loaded
                
                if let listItems = self.listItems, listItems.contains(where: { (item) -> Bool in
                    return item.type == .ONLINE_TRIP_HEADER
                }) && !forceReload {
                    refreshControl.endRefreshing()
                    self.sourceSwitch.isEnabled = true
                    return
                }
                
                // Online
                self.listItems = [ActivityFeedItem]()
                tableView.reloadData()
                let criteria = GetMyActivityFeedCriteria(includeExtProperties: true) // Default criteria
                loadOnlineTrips(criteria: criteria) {[weak self] in
                    self?.reloadTableData()
                    self?.sourceSwitch.isEnabled = true
                }
            } else {
                self.listItems = [ActivityFeedItem]()
                showError("No Internet Connection".toError())
                reloadTableData()
                self.sourceSwitch.isEnabled = true
            }
        }
    }
    
    private func loadOnlineTrips(criteria: GetMyActivityFeedCriteria, callback: @escaping () -> Void) {
        let service = ServiceFactory.getTripService()
        service.getMyActivityFeed(criteria: criteria, fetchConfig: TripFetchConfig()) { result in
            if case let .success(value) = result {
                let trips = self.convertToFeedItem(trips: value.entries)
                self.listItems = trips
                callback()
            } else {
                self.listItems = [ActivityFeedItem]()
                callback()
                self.showError((result.errorMessage ?? "Unknown error").toError())
            }
        }
    }

    func loadRecordedTrips(criteria: TripRecordingSearchCriteria) throws {
        self.tripService = ServiceFactory.getTripRecordingService()
        
        if let tripService = self.tripService {
            let recordings = try tripService.findTripRecordings(criteria: criteria)
            self.listItems = convertRecordedTripToFeedItem(tripRecordings: recordings)
        }
    }

    // MARK:-
    private func convertRecordedTripToFeedItem(tripRecordings: [TripRecordingBasicInfo]) -> [ActivityFeedItem] {
        return tripRecordings.map { (recording) -> ActivityFeedItem in
            ActivityFeedRecordedTripItem(info: recording)
        }
    }
    
    func setUpNavBar() {
        let buttonAdd = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.buttonAddTapped))
        
        self.homeNavItem?.setRightBarButtonItems([buttonAdd], animated: false)
    }
    
    // MARK:- Notifications
    
    private func onTripUploadStatusChanged(notification: Notification) {
        requiresReload = true
    }
    
    private func ontTripStatusChanged(notification: Notification) {
        if let statusChange = notification.userInfo?[TripRecordingStatusChangeNotification.name.rawValue] as? TripRecordingStatusChange {
            Log.d(TAG, statusChange.compositeId.description)
            Log.d(TAG, statusChange.status.name)

            loadTrips(forceReload: true)
        }
    }
}
