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

class MyTripsViewController: BaseViewController {
    
    private let TAG = "MyTripsViewController"
    
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    let lblNoRecords = UILabel()
    
    var tripService: ITripRecordingService?
    var myTrips: [TripRecording]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
        tableView.tableFooterView = UIView()
                
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        
        lblNoRecords.text = "NO SAVED TRIPS"
        lblNoRecords.numberOfLines = 1
        lblNoRecords.textAlignment = .center
        lblNoRecords.textColor = .systemGray
        lblNoRecords.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/3, width: UIScreen.main.bounds.width, height: 25)
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        do {
            try loadTrips()
        } catch {
            showError(error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpNavBar()
        do {
            try loadTrips()
        } catch {
            showError(error)
        }
    }

    func loadTrips() throws {
        self.tripService = ServiceFactory.getTripRecordingService()
        
        if let tripService = self.tripService {
            self.myTrips = try tripService.findTripsForActivities()
            self.tableView.reloadData()
            
            self.refreshControl.endRefreshing()
            
            self.lblNoRecords.removeFromSuperview()
            if ((self.myTrips?.count ?? 0) <= 0) {
                view.addSubview(self.lblNoRecords)
            }
        }
    }
    
    func setUpNavBar() {
        let buttonAdd = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.buttonAddTapped))
        buttonAdd.tintColor = UIColor.Active

        self.homeNavItem?.setRightBarButtonItems([buttonAdd], animated: false)
    }
    
    @objc func buttonAddTapped() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "RecordNewTripChooseVC") as? RecordNewTripChooseViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func openSaveTripView(tripUuid: String, completion: (() -> Void)?) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "SaveTripVC") as? SaveTripViewController {
            vc.tripUuid = tripUuid
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: completion)
        }
    }
}

extension MyTripsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.myTrips?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TripListTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TripListCell", for: indexPath) as! TripListTableViewCell
        if let trip = self.myTrips?[indexPath.row] {
            cell.setTrip(trip: trip)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let trip = self.myTrips?[indexPath.row] {
            switch trip.recordingInfo.status {
            case .RECORDING, .PAUSED:
                if let vc = UIStoryboard(name: "Main", bundle: nil) .
                    instantiateViewController(withIdentifier: "RecordNewTripVC") as? RecordNewTripViewController {
                    vc.title = "Record New Free Roam Trip"
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .FINISHED:
                self.openSaveTripView(tripUuid: trip.tripInfo.uuid, completion: nil)
            case .QUEUED, .UPLOADED:
                self.openSaveTripView(tripUuid: trip.tripInfo.uuid, completion: nil)
            default:
                break
            }
        }        
    }
}
