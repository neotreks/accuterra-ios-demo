//
//  DrivingViewController.swift
//  DemoApp
//
//  Created by Richard Cizovsky on 11/05/2020.
//  Copyright © 2019 NeoTreks. All rights reserved.
//

import UIKit
import Mapbox
import AccuTerraSDK

// MARK:- Enums
enum WaypointListSliderMode: Int {
    case minimum = 0
    case maximum
}

class DrivingViewController: BaseTripRecordingViewController {

    // MARK:- Outlets
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var expandButton: UIButton!

    @IBOutlet weak var nextNextPoiInfo: UIView!
    @IBOutlet weak var nextNextNextPoiDistanceLabel: UILabel!
    @IBOutlet weak var nextNextNextPoiNameLabel: UILabel!

    @IBOutlet weak var directionImageView: UIImageView!
    @IBOutlet weak var distanceToWaypointLabel: UILabel!
    @IBOutlet weak var waypointNameLabel: UILabel!
    @IBOutlet weak var wrongDirectionLabel: UILabel!
    @IBOutlet weak var trailLostLabel: UILabel!

    // Note: for the full screen list we stop resizing map, but rather resize
    // the TrailsListView.
    @IBOutlet weak var listViewHeightFullConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapViewHeightClosedConstraint: NSLayoutConstraint!

    // MARK:- Properties
    private let TAG = "DrivingViewController"
    private var trail: Trail?

    private var navigatorStatus = NavigatorStatus.createNotReady() {
        didSet {
            switch navigatorStatus.status {
            case .NOT_READY:
                // nothing to do
                break
            case .NAVIGATING:
                showNextWayPointLabels(situation: navigatorStatus.nextWayPoint!)
                do {
                    try mapView.trailLayersManager.highlightPOI(poiId: navigatorStatus.nextWayPoint!.trailPOI.id)
                } catch {
                    showError(error)
                }
            case .FINISHED:
                showNavigationFinishedLabels(situation: navigatorStatus.nextWayPoint!)
            case .TRAIL_LOST:
                showTrailLost()
            case .WRONG_DIRECTION:
                showWrongDirection()
            }
        }
    }

    private var trailNavigator: ITrailNavigator?
    private var trailDrive: TrailDrive?
    
    private lazy var sortedWayPoints = [TrailDriveWaypoint]()
    private var nextExpectedWayPoint: TrailDriveWaypoint? = nil
    var waypointsListView: WaypointListView = UIView.fromNib()
    var waypointListSliderMode: WaypointListSliderMode = .minimum

    // MARK:- Lifecycle
    override func viewDidLoad() {
        self.title = "Driving Mode"

        let item = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close))

        self.navigationItem.leftBarButtonItem = item
        setupListView()

        self.nextNextNextPoiNameLabel.text = nil
        self.nextNextNextPoiDistanceLabel.text = nil
        self.nextNextPoiInfo.isHidden = false
        self.waypointNameLabel.text = ""
        self.distanceToWaypointLabel.text = ""
        self.directionImageView.image = nil
        self.trailLostLabel.isHidden = true
        self.wrongDirectionLabel.isHidden = true
        self.contentView.isHidden = true
        self.expandButton.isSelected = false
        simulateTrailPath =  Bundle.main.infoDictionary?["SIMULATE_TRAIL_PATH"] as? Bool ?? false
        
        super.viewDidLoad()
    
        setupMap()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.contentView.subviews.contains(waypointsListView) {
            self.contentView.insertSubViewWithInset(view: waypointsListView, insets: UIEdgeInsets.init())
        }
    }

    // MARK:- IBActions
    @IBAction func expandButtonPressed() {
        self.expandButton.isSelected = !self.expandButton.isSelected
        self.contentView.isHidden = !self.expandButton.isSelected
        self.nextNextPoiInfo.isHidden = self.expandButton.isSelected
    }

    // MARK:- Actions
    @objc func close() {
        guard !tripRecorder.hasActiveTripRecording() else {
            showError("Cannot exit while recording a trip".toError())
            return
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK:-
    func setupListView() {
        waypointsListView.delegate = self
    }

    override func getTrailDrive() -> TrailDrive? {
        guard let trailId = trailId else {
            return nil
        }
        let trailService = ServiceFactory.getTrailService()
        // Use the first drive for now. Later allow user to select which one
        return try? trailService.getTrailDrives(trailId).first
    }
    
    private func showNextWayPointLabels(situation: NextWayPoint) {

        var direction: TrailNavigator.Direction? = nil
        var distance: Float? = nil
        switch situation.direction {
        case .AT_POINT:
            direction = nil
            distance = nil
        default:
            direction = situation.direction
            distance = situation.distance
        }

        showNextWayPointToolbar(direction: direction, distance: distance, title: situation.trailPOI.point.name ?? "End")
        displayNextNextPoiInfo(situation: situation)
    }

    private func showNavigationFinishedLabels(situation: NextWayPoint) {
        showNextWayPointToolbar(direction: TrailNavigator.Direction.AT_POINT, distance: nil, title: situation.trailPOI.point.name ?? "End")
    }

    private func showNextWayPointToolbar(direction: TrailNavigator.Direction?,
                                         distance: Float?,
                                         title: String) {

        if let direction = direction {
            switch direction {
            case .AT_POINT:
                self.directionImageView.image = UIImage(systemName: "scope")
            case .FORWARD:
                self.directionImageView.image = UIImage(systemName: "arrow.up")
            case .BACKWARD:
                self.directionImageView.image = UIImage(systemName: "arrow.down")
            @unknown default:
                return
            }
        } else {
            self.directionImageView.image = nil
        }

        if let distance = distance {
            distanceToWaypointLabel.text = "\(DistanceFormatter.formatDistance(distanceInMeters: distance))"
        } else {
            distanceToWaypointLabel.text = ""
        }

        waypointNameLabel.text = title
        wrongDirectionLabel.isHidden = true
        trailLostLabel.isHidden = true
    }

    private func displayNextNextPoiInfo(situation: NextWayPoint) {
        guard let waypoints = waypointsListView.waypoints else {
            return
        }
        // Scroll to nex position if possible
        guard let selectedIndex = waypoints.firstIndex(where: { (wp) -> Bool in
            return wp.id == situation.trailPOI.id
        }) else {
            // Nothing is selected -> nothing to display
            nextNextNextPoiDistanceLabel.text = ""
            nextNextNextPoiNameLabel.text = ""
            return
        }

        let count = waypoints.count

        // Get the nextNext item but avoid out of index
        let nextNextItem: TrailDriveWaypoint?
        if count > selectedIndex + 1 {
            nextNextItem = waypoints[selectedIndex + 1]
        } else {
            // Select the last one
            nextNextItem = waypoints.last
        }

        // Update the next next point labels
        nextNextNextPoiNameLabel.text = nextNextItem?.point.name

        if let distance = nextNextItem?.distanceMarker {
            distanceToWaypointLabel.text = "\(DistanceFormatter.formatDistance(distanceInMeters: distance))"
        } else {
            distanceToWaypointLabel.text = ""
        }
    }

    private func showTrailLost() {
        waypointNameLabel.text = ""
        distanceToWaypointLabel.text = ""
        directionImageView.image = nil
        wrongDirectionLabel.isHidden = true
        trailLostLabel.isHidden = false
    }

    private func showWrongDirection() {
        waypointNameLabel.text = ""
        distanceToWaypointLabel.text = ""
        directionImageView.image = nil
        wrongDirectionLabel.isHidden = false
        trailLostLabel.isHidden = true
    }

    func onTrailPoiClicked(wayPoint: TrailDriveWaypoint) {
        exitDrivingMode()
        zoomToWayPoint(wayPoint: wayPoint.point)
        do {
            try mapView.trailLayersManager.highlightPOI(poiId: wayPoint.point.id)
        } catch {
            showError(error)
            return
        }
        waypointsListView.selectWaypointPoint(waypointId: wayPoint.id)
        if (waypointListSliderMode != .maximum) {
            expandButtonPressed()
        }
    }

    override func onLocationUpdated(location: CLLocation) {
        super.onLocationUpdated(location: location)
        do {
            try trailNavigator?.evaluateLocation(location: location)
        } catch {
            showError(error)
        }
    }

    private func addTrailLayers() {
        guard SdkManager.shared.isTrailDbInitialized, let trailId = self.trailId else {
            return
        }
        let trailLayersManager = mapView.trailLayersManager
        trailLayersManager.delegate = self

        do {
            guard let trail = try ServiceFactory.getTrailService().getTrailById(trailId) else {
                return
            }
            
            let filter = TrailLoadFilter(trailIds: [trail.info.id])
            try trailLayersManager.addStandardLayers(trailLoadFilter: filter)
            filterTrail(trail: trail)
            try initializeTrailNavigator(trailId: trailId)
        } catch {
            showError(error)
        }
    }
    private func initializeTrailNavigator(trailId: Int64) throws {
        let trailService = ServiceFactory.getTrailService()
        // Use the first drive for now. Later allow user to select which one
        let drive = try trailService.getTrailDrives(trailId).first
        if let firstDrive = drive  {
            let service = ServiceFactory.getTrailNavigatorService()
            var navigator = try service.getTrailNavigator(trailDrive: firstDrive)
            self.trailNavigator = navigator
            self.trailNavigator?.delegate = self
            if let lastKnownLocation = LocationService.shared.lastReportedLocation {
                if let nextWaypoint = try navigator.findPossibleNextWayPoints(location: lastKnownLocation).first {
                    navigator.nextExpectedWayPoint = nextWaypoint
                }
            }

            self.waypointsListView.loadWaypoints(trailDrive: firstDrive)
            if let nextExpectedWayPoint = self.trailNavigator?.nextExpectedWayPoint {
                // restore the navigator
                self.nextExpectedWayPoint = nextExpectedWayPoint
            }
            else {
                throw "Trail path not found".toError()
            }
            if let lastKnownLocation = LocationService.shared.lastReportedLocation {
                try trailNavigator?.evaluateLocation(location: lastKnownLocation)
            }
        }
    }

    private func filterTrail(trail: Trail) {
        Log.i(TAG, "filterTrail(trail=\(trail.info.id)")

        let trailLayersManager = mapView.trailLayersManager

        trailLayersManager.setVisibleTrails(trailIds: [trail.info.id])
        do {
            try trailLayersManager.highLightTrail(trailId: trail.info.id)
        } catch {
            showError(error)
        }

        trailLayersManager.showTrailPOIs(trail: trail)
    }
}

// MARK:- Map methods
extension DrivingViewController {
    override func onMapLoaded() {
        super.onMapLoaded()
        self.addTrailLayers()
        do {
            try setupRecordingAfterOnAccuTerraMapViewReady()
        } catch {
            showError(error)
        }
    }
}

// MARK:- Navigation methods
extension DrivingViewController {
    private func updateNavigatorStatus(status: NavigatorStatus) {

        self.navigatorStatus = status

        if let nextWaypoint = status.nextWayPoint {
            let isNewWayPoint = self.nextExpectedWayPoint?.id != status.nextWayPoint?.trailPOI.id
            self.nextExpectedWayPoint = status.nextWayPoint?.trailPOI

            if (isNewWayPoint && waypointListSliderMode != .minimum) {
                waypointsListView.selectWaypointPoint(waypointId: nextWaypoint.trailPOI.id)
            }
        }
    }
}

// MARK:- TrailNavigatorDelegate extension
extension DrivingViewController: TrailNavigatorDelegate {
    func onChange(location: CLLocation, situation: NextWayPoint) {
        updateNavigatorStatus(status: NavigatorStatus.createNavigating(location: location, situation: situation))
    }
    
    func onTrailEndReached(location: CLLocation, situation: NextWayPoint) {
        updateNavigatorStatus(status: NavigatorStatus.createFinished(location: location, situation: situation))
    }
    
    func onLocationIgnored(location: CLLocation) {
        // nothing to do
    }
    
    func onTrailLost(location: CLLocation) {
        updateNavigatorStatus(status: NavigatorStatus.createTrailLost(location: location))
    }
    
    func onWrongDirection(location: CLLocation) {
        updateNavigatorStatus(status: NavigatorStatus.createWrongDirection(location: location))
    }
}

// MARK:- TrailLayersManagerDelegate extension
extension DrivingViewController : TrailLayersManagerDelegate {
    func onLayersAdded(trailLayers: Array<TrailLayerType>) {
        do {
            try mapView.trailLayersManager.highLightTrail(trailId: self.trailId)
        } catch {
            showError(error)
        }
        switchToDrivingMode()
    }
}

// MARK:- WaypointListViewDelegate extension
extension DrivingViewController : WaypointListViewDelegate {
    func didSelectWayPoint(wayPoint: TrailDriveWaypoint) {
        self.onTrailPoiClicked(wayPoint: wayPoint)
    }
    
    func didPressDetailButton(cell: WaypointListTableviewCell) {
        if let index = waypointsListView.tableView.indexPath(for: cell), let waypoint = waypointsListView.waypoints?[index.row] {
            
            if let vc = UIStoryboard(name: "Main", bundle: nil) .
                instantiateViewController(withIdentifier: "TrailPoiDetailVC") as? TrailPoiDetailViewController {
                vc.trailDriveWaypoint = waypoint
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
