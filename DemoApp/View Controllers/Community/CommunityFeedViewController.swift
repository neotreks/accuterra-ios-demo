//
//  CommunityViewController.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/18/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Reachability

class CommunityFeedViewController: ActivityFeedBaseViewController {

    // MARK:- Static
    private static let DEFAULT_LOCATION = MapLocation(latitude: 39.742043, longitude: -104.991531) // Denver

    // MARK:- Properties

    /// Location used for filtering the activity feed
    private var location: MapLocation = CommunityFeedViewController.DEFAULT_LOCATION
    private func hasLocation() -> Bool {
        return location != CommunityFeedViewController.DEFAULT_LOCATION
    }

    // MARK:- Loaders
    override func loadTrips(forceReload: Bool) {
        self.refreshControl.beginRefreshing()
        if !hasLocation() {
            // Try to get the location
            location = SdkLocationUtil.shared.getLastKnownMapLocation(defaultLocation: CommunityFeedViewController.DEFAULT_LOCATION)
        }
        if isOnline {
            // Check if not already loaded
            
            if let listItems = self.listItems, listItems.contains(where: { (item) -> Bool in
                return item.type == .ONLINE_TRIP_HEADER
            }) && !forceReload {
                refreshControl.endRefreshing()
                return
            }
            
            // Online
            let criteria = GetCommunityFeedCriteria(location: location) // Default criteria
            loadCommunityTrips(criteria: criteria) {
                self.reloadTableData()
            }
        } else {
            self.listItems = [ActivityFeedItem]()
            showError("No Internet Connection".toError())
            reloadTableData()
        }
    }

    private func loadCommunityTrips(criteria: GetCommunityFeedCriteria, callback: @escaping () -> Void) {
        let service = ServiceFactory.getTripService()
        service.getCommunityFeed(criteria: criteria) { result in
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
}
