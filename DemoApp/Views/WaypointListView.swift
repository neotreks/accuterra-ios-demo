//
//  WaypointListView.swift
//  DemoApp
//
//  Created by Richard Cizovsky on 13/5/2019.
//  Copyright © 2019 NeoTreks. All rights reserved.
//
import UIKit
import AccuTerraSDK

protocol WaypointListViewDelegate : class {
    func didSelectWayPoint(wayPoint: TrailDriveWaypoint)
    func didPressDetailButton(cell: WaypointListTableviewCell)
}

class WaypointListView: UIView {
    
    private let TAG = "WaypointListView"
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: WaypointListViewDelegate?
    
    var trailsService: ITrailService?
    var trailDrive: TrailDrive?
    var waypoints: Array<TrailDriveWaypoint>?
    
    private var selectedWaypointId: Int64?
    
    func loadWaypoints(trailDrive:TrailDrive)  {
        self.trailDrive = trailDrive
        tableView.register(UINib(nibName: WaypointListTableviewCell.cellXibName, bundle: nil), forCellReuseIdentifier: WaypointListTableviewCell.cellIdentifier)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        guard self.delegate != nil else {
            Log.e(TAG, "WaypointListView delegate not set")
            return
        }
        guard SdkManager.shared.isTrailDbInitialized else {
            return
        }
        
        self.waypoints = trailDrive.waypoints
        
        self.tableView.reloadData()
    }
    
    func selectWaypointPoint(waypointId: Int64?) {
        self.selectedWaypointId = waypointId
        guard let waypointId = waypointId else {
            self.tableView.selectRow(at: nil, animated: false, scrollPosition: UITableView.ScrollPosition.none)
            return
        }
        if let mapPoints = self.waypoints, let index = mapPoints.firstIndex(where: { (t) -> Bool in
            return t.id == waypointId
        }) {
            self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.none)
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
        }
    }
}

extension WaypointListView : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.waypoints?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let waypoint = self.waypoints?[indexPath.row], let text = waypoint.description {
            return WaypointListTableviewCell.getEstimatedHeightInTable(table: tableView, text: text)
        } else {
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let waypoint = self.waypoints?[indexPath.row], let text = waypoint.description {
            return WaypointListTableviewCell.getEstimatedHeightInTable(table: tableView, text: text)
        } else {
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :WaypointListTableviewCell = tableView.dequeueReusableCell(withIdentifier: WaypointListTableviewCell.cellIdentifier, for: indexPath) as! WaypointListTableviewCell
        
        let waypoint = self.waypoints?[indexPath.row]
        
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
        
        cell.delegate = self.delegate
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let waypoints = self.waypoints else {
            return indexPath
        }
        self.delegate?.didSelectWayPoint(wayPoint: waypoints[indexPath.row])
        self.selectedWaypointId = waypoints[indexPath.row].id
        return indexPath
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}



