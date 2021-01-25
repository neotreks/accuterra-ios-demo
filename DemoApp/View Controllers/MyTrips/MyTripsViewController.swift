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

class MyTripsViewController: ActivityFeedBaseViewController {

    // MARK:- Outlets
    @IBOutlet weak var sourceSwitch: UISwitch!

    // MARK:- Properties
    private let TAG = "MyTripsViewController"
    var tripService: ITripRecordingService?

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavBar()
    }

    // MARK:- IBActions
    @IBAction func sourceSwitchValueChanged() {
        loadTrips(forceReload: true)
        setUpNavBar()
    }

    // MARK:- Actions
    @objc func buttonAddTapped() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "RecordNewTripChooseVC") as? RecordNewTripChooseViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK:- Loaders
    override func loadTrips(forceReload: Bool) {
        self.sourceSwitch.isEnabled = false
        self.refreshControl.beginRefreshing()
        if sourceSwitch.isOn {
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
            if (isOnline) {
                // Check if not already loaded
                
                if let listItems = self.listItems, listItems.contains(where: { (item) -> Bool in
                    return item.type == .ONLINE_TRIP_HEADER
                }) && !forceReload {
                    refreshControl.endRefreshing()
                    self.sourceSwitch.isEnabled = true
                    return
                }
                
                // Online
                tableView.reloadData()
                let criteria = GetMyActivityFeedCriteria() // Default criteria
                loadOnlineTrips(criteria: criteria) {
                    self.reloadTableData()
                    self.sourceSwitch.isEnabled = true
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
        service.getMyActivityFeed(criteria: criteria) { result in
            if let value = result.value, result.isSuccess {
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
        if sourceSwitch.isOn {
            let buttonAdd = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.buttonAddTapped))
            buttonAdd.tintColor = UIColor.Active
            
            self.homeNavItem?.setRightBarButtonItems([buttonAdd], animated: false)
        } else {
            self.homeNavItem?.setRightBarButtonItems([], animated: false)
        }
    }
}
