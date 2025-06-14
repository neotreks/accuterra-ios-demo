//
//  DiscoverViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 20/12/2019.
//  Copyright © 2019 NeoTreks. All rights reserved.
//

import UIKit
import MapLibre
import AccuTerraSDK
import Reachability
import Combine

// MARK:- Enums
enum TrailListSliderMode: Int {
    case closed = 0
    case partial
    case full
}

class DiscoverViewController: BaseViewController {

    // MARK:- Outlets
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var mapView: AccuTerraMapView!
    @IBOutlet weak var contentViewTopConstraint: NSLayoutConstraint!
    /// Note: for the full screen list we stop resizing map, but rather resize
    /// the TrailsListView.
    @IBOutlet weak var listViewHeightFullConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapViewHeightClosedConstraint: NSLayoutConstraint!
    @IBOutlet weak var myLocationButton: UIButton!
    @IBOutlet weak var layersButton: UIButton!

    /// Shows caching progress for trail or overlay
    @IBOutlet weak var cacheProgressView: UILabelledProgressView!
    @IBOutlet weak var cacheProgressHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapLoadingIndicator: UIActivityIndicatorView!

    // MARK:- Properties
    private let TAG = LogTag(subsystem: "ATDemoApp", category: "DiscoverViewController")
    
    var searchController: UISearchController?
    var trailsListView: TrailListView = UIView.fromNib()
    
    var initLoading : Bool = true
    var mapWasLoaded : Bool = false
    var trailListSliderMode:TrailListSliderMode = .partial
    var isTrailsLayerManagersLoaded = false
    var trailsFilter = TrailsFilter()
    var trailFilterButton: UIButton?
    private var enableHeadingTask: Task<Void, Never>?

    // Location tracking mode
    private var currentTracking = TrackingOption.NONE_WITH_LOCATION
    private var lastGpsTracking: TrackingOption?

    // Available tracking options
    private let trackingOptions: [TrackingOption] =
        [.LOCATION, .NONE_WITH_LOCATION]
    
    private var cancellableRefs = [AnyCancellable]()
    
    var trailService: ITrailService?
    
    /// List of styles, the layers button cycles through them
    var styles: [URL] = [AccuTerraStyle.vectorStyleURL, ApkHereMapClass().styleURL]
    
    /// Offline supported styles
    var offlineStyles: [URL] = [ApkHereMapClass().styleURL, AccuTerraStyle.vectorStyleURL]
    
    /// Current style Id
    var styleId = 0

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // There is a crash in MapLibre when heading is animating while device rotates. We want to hide the heading and
        // show it later when animation finishes. We are using task with delay to do this.
        mapView.compassView.isHidden = true
        if let enableHeadingTask {
            enableHeadingTask.cancel()
        }
        enableHeadingTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds:1_000_000_000)
                DispatchQueue.main.async {
                    self?.mapView.compassView.isHidden = false
                }
            } catch {
                return
            }
        }
    }

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        goToTrailsDiscovery()
        
        // Monitor network reachability changes
        NotificationCenter.default
            .publisher(for: Notification.Name.reachabilityChanged)
            .compactMap({$0.object as? Reachability})
            .receive(on: DispatchQueue.main)
            .sink() { [weak self] reachability in
                guard let self = self else {
                    return
                }
                if reachability.connection == .unavailable {
                    self.tryOrShowError {
                        // When network is not available we want to switch to offline style, but only if it's cached
                        if let status = try OfflineMapManager.shared.getOverlayOfflineMap()?.status,
                           status == .COMPLETE {
                            if self.mapView.isStyleLoaded {
                                let currentStyle = self.styles[self.styleId]
                                if !self.offlineStyles.contains(currentStyle) {
                                    try self.cycleStyle()
                                }
                            }
                        } else {
                            self.layersButton.isEnabled = false
                        }
                    }
                } else {
                    self.layersButton.isEnabled = true
                }
            }
            .store(in: &cancellableRefs)

        NotificationCenter.default.publisher(for: Notification.Name.TrailsUpdated, object: nil)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let visibleTrails = self.trailsListView.loadTrails()
                    self.mapView.trailLayersManager.setVisibleTrails(trailIds: visibleTrails)
                }
            }
            .store(in: &cancellableRefs)

        OfflineMapManager.shared.addProgressObserver(observer: self)

        // Hide cache indicator
        cacheProgressHeightConstraint.constant = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSearchBar()

        if let last = lastGpsTracking {
            setLocationTracking(trackingOption: last)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setLocationTracking(trackingOption: TrackingOption.NONE)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.contentView.subviews.contains(trailsListView) {
            self.contentView.insertSubViewWithInset(view: trailsListView, insets: UIEdgeInsets.init())
        }
    }

    // MARK:- IBActions
    @IBAction func myLocationPicked(_ sender: Any) {
        let isMapTracking = mapView.isTrackingCameraMode
        let lastGpsTracking = self.lastGpsTracking
        if isMapTracking || lastGpsTracking == nil {
            let newTracking: TrackingOption = UIUtils.loopNextElement(
                    array: trackingOptions, currentElement: currentTracking
            )
            setLocationTracking(trackingOption: newTracking)
        } else {
            setLocationTracking(trackingOption: lastGpsTracking!)
        }
    }

    @IBAction func layersPressed(_ sender: Any) {
        self.layersButton.isEnabled = false
        tryOrShowError {
            try self.cycleStyle()
        }
    }

    // MARK:- Actions

    @objc func searchTapped() {
        self.searchController = UISearchController(searchResultsController:  nil)
        self.searchController?.hidesNavigationBarDuringPresentation = false
        self.searchController?.obscuresBackgroundDuringPresentation = false
        self.searchController?.searchBar.placeholder = "Trail Name"
        self.searchController?.searchBar.text = self.trailsFilter.trailNameFilter
        definesPresentationContext = true
        self.searchController?.searchBar.delegate = self
        self.homeNavItem?.titleView = searchController?.searchBar

        self.searchController?.searchBar.showsCancelButton = true
        self.searchController?.searchBar.becomeFirstResponder()
        self.taskBar?.isUserInteractionEnabled = false
        self.homeNavItem?.setRightBarButtonItems(nil, animated: false)
        showTrailListPartialMode()
    }

    @objc func filterTapped() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "FilterController") as? FilterViewController {
            vc.modalPresentationStyle = .overCurrentContext
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
            vc.initialize(trailsFilter: self.trailsFilter)
        }
    }

    // MARK:-
    func goToTrailsDiscovery() {
        if SdkManager.shared.isTrailDbInitialized {
            self.trailService = ServiceFactory.getTrailService()
        }
        
        // Initialize map
        self.mapView.initialize(styleURL: styles[styleId], styleProvider: getStyleProvider(style: styles[styleId]))

        trailsListView.delegate = self
        
        myLocationButton.layer.cornerRadius = 20.0
        myLocationButton.dropShadow()
        
        layersButton.layer.cornerRadius = 20.0
        layersButton.dropShadow()
    }
    
    func cycleStyle() throws {
        styleId += 1
        if styleId == styles.count {
            styleId = 0
        }
        let style = styles[styleId]
        if !NetworkUtils.shared.isOnline() && !offlineStyles.contains(style) {
            
            // If this style is not available offline, cycle to next
            
            try cycleStyle()
            return
        }
        try self.mapView.setStyle(styleURL:style, styleProvider:getStyleProvider(style: style))
    }

    /// Get the [IAccuTerraStyleProvider] to be able to customize styles
    /// of trail paths, waypoints, markers, etc.
    private func getStyleProvider(style: URL) -> IAccuTerraStyleProvider? {
        if isSatellite(style: style) {
            return AccuTerraSatelliteStyleProvider(mapStyle:style)
        }
        else {
            return AccuTerraStyleProviderTrailCollection(mapStyle:style)
        }
    }
    
    func isSatellite(style:URL) -> Bool {
        if let _ = style.absoluteString.range(of: "HERESatelliteStyle", options: .caseInsensitive) {
            return true
        }
        else {
            return false
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        self.navigationController?.navigationBar.isTranslucent = true
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        self.navigationController?.navigationBar.isTranslucent = false
    }

    var isSearchBarEmpty: Bool {
        return self.searchController?.searchBar.text?.isEmpty ?? true
    }
    
    func setUpSearchBar() {
        let searchButton = UIButton(type: .system)
        searchButton.tintColor = UIColor.Active
        searchButton.setImage(UIImage.searchImage, for: .normal)
        searchButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        searchButton.addTarget(self, action:#selector(self.searchTapped), for: .touchUpInside)
        
        let filterButton = UIButton(type: .system)
        filterButton.tintColor = UIColor.Active
        filterButton.setImage(UIImage.filterImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        filterButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        filterButton.addTarget(self, action:#selector(self.filterTapped), for: .touchUpInside)
        self.homeNavItem?.setRightBarButtonItems([
            UIBarButtonItem(customView: filterButton),
            UIBarButtonItem(customView: searchButton)
        ], animated: false)
        self.trailFilterButton = filterButton
        self.homeNavItem?.titleView = nil
    }
    
    private func showTrailInfo(basicInfo: TrailBasicInfo) {
        let infoViewController = TrailInfoViewController()
        infoViewController.title = "Trail Info"
        infoViewController.delegate = self
        infoViewController.trailId = basicInfo.id
        self.navigationController?.pushViewController(infoViewController, animated: true)
    }
    
    private func onLoadTrailDetail(basicInfo: TrailBasicInfo) {
        self.showTrailInfo(basicInfo: basicInfo)
    }
    
    private func zoomToDefaultExtent() {
        // Colorado’s bounds
        let northeast = CLLocationCoordinate2D(latitude: 40.989329, longitude: -102.062592)
        let southwest = CLLocationCoordinate2D(latitude: 36.986207, longitude: -109.049896)
        let colorado = MLNCoordinateBounds(sw: southwest, ne: northeast)

        mapView.zoomToExtent(bounds: colorado, animated: true)
    }
    
    private func zoomToTrail(locationInfo: TrailLocationInfo) {
        let extent = MLNCoordinateBounds(sw: locationInfo.mapBounds.sw.coordinates, ne: locationInfo.mapBounds.ne.coordinates)
        self.mapView.zoomToExtent(bounds: extent, edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: true)
    }
    
    /// Set location tracking, changes icon of my location button.
    /// Triggers permission request if permission is required
    func setLocationTracking(trackingOption: TrackingOption) {
        currentTracking = trackingOption
        if trackingOption.isTrackingOption {
            lastGpsTracking = trackingOption
        }

        mapView.setTracking(mode: trackingOption)
    }
    
    /**
     * Returns the current state of the location permissions needed.
     */
    func hasLocationPermissions() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .denied:
            return false
        default:
            return true
        }
    }
    
    private func setTrailNameFilter(trailNameFilter: String?) {
        self.trailsFilter.trailNameFilter = trailNameFilter

        if let filterName = trailNameFilter, filterName.count > 0 {
            self.homeNavItem?.title = filterName
            self.trailFilterButton?.isUserInteractionEnabled = false
            self.trailFilterButton?.tintColor = UIColor.lightGray
        } else {
            self.homeNavItem?.title = String.appTitle
            self.trailFilterButton?.isUserInteractionEnabled = true
            self.trailFilterButton?.tintColor = UIColor.Active
        }

        let visibleTrails = self.trailsListView.loadTrails()
        self.mapView.trailLayersManager.setVisibleTrails(trailIds: visibleTrails)
    }
}

// MARK:- AccuTerraMapViewDelegate extension
extension DiscoverViewController : AccuTerraMapViewDelegate {

    func onMapLoadFailed(error: Error) {
        mapLoadingIndicator.stopAnimating()
        showError(error)
    }

    func onStyleChangeFailed(error: Error) {
        showError(error)
    }
    
    func onTrackingModeChanged(mode: TrackingOption) {
        let icon = UIUtils.getLocationTrackingIcon(trackingOption: mode)
        myLocationButton.setImage(icon, for: .normal)
    }
    
    func didTapOnMap(coordinate: CLLocationCoordinate2D) {
        guard self.isTrailsLayerManagersLoaded else {
            return
        }
        
        tryOrShowError {
            if try !searchPois(coordinate: coordinate) {
                let _ = try searchTrails(coordinate: coordinate)
            }
        }
    }
    
    func handleTrailMapClick(trailId: Int64?) {
        self.showTrailPOIs(trailId: trailId)
        tryOrShowError {
            try mapView.trailLayersManager.highLightTrail(trailId: trailId)
        }
        self.trailsListView.selectTrail(trailId: trailId)
    }
    
    func handleTrailPoiMapClick(trailId: Int64, poiId: Int64) {
        do {
            if let trailManager = self.trailService,
                let trail = try trailManager.getTrailById(trailId),
                let poi = trail.navigationInfo?.mapPoints.first(where: { (point) -> Bool in
                    return point.id == poiId
                }) {
                AlertUtils.showAlert(viewController: self, title: poi.name ?? "\(poiId)", message: poi.description ?? "")
            }
        }
        catch {
            Log.e(TAG, error)
        }
    }
    
    func searchTrails(coordinate: CLLocationCoordinate2D) throws -> Bool {
        let query = try TrailsQuery(
            trailLayersManager: mapView.trailLayersManager,
            layers: Set(TrailLayerType.allValues),
            coordinate: coordinate,
            distanceTolerance: 2.0)
        
        let trailId = try query.execute().trailIds.first
        handleTrailMapClick(trailId: trailId)
        
        return trailId != nil
    }
    
    func searchPois(coordinate: CLLocationCoordinate2D) throws -> Bool {
        let query = try TrailPoisQuery(
            trailLayersManager: mapView.trailLayersManager,
            layers: Set(TrailPoiLayerType.allValues),
            coordinate: coordinate,
            distanceTolerance: 2.0)
        
        if let trailPoi = try query.execute().trailPois.first, let poiId = trailPoi.poiIds.first {
            handleTrailPoiMapClick(trailId: trailPoi.trailId , poiId: poiId)
            return true
        } else {
            return false
        }
    }
    
    func onMapLoaded() {
        mapLoadingIndicator.stopAnimating()
        // Used to zoom to user when app starts
        if self.initLoading == true && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            self.initLoading = false
        }
        self.layersButton.isHidden = false
        self.mapWasLoaded = true
        setLocationTracking(trackingOption: .NONE_WITH_LOCATION)
        self.zoomToDefaultExtent()
        tryOrShowError {
            try self.addTrailLayers()
        }
        
        if NetworkUtils.shared.isOnline() {
            tryOrShowError {
                try checkOverlayMapCache()
            }
        }
    }
    
    func onStyleChanged() {
        self.layersButton.isEnabled = true
    }
    
    func onSignificantMapBoundsChange() {
        self.refreshTrailListByMapBoundFilter()
    }

    private func addTrailLayers() throws {
        guard SdkManager.shared.isTrailDbInitialized else {
            return
        }
        let trailLayersManager = mapView.trailLayersManager

        trailLayersManager.delegate = self
        try trailLayersManager.addStandardLayers()
    }
    
    func refreshTrailListByMapBoundFilter() {
        if trailListSliderMode != .full {
            if let newBoundingBoxFilter = try? getMapBounds() {
                if let previousBoundingBoxFilter = self.trailsFilter.boundingBoxFilter {
                    if previousBoundingBoxFilter.equals(bounds: newBoundingBoxFilter) {
                        return
                    }
                }
                self.trailsFilter.boundingBoxFilter = newBoundingBoxFilter
                let visibleTrails = self.trailsListView.loadTrails()
                self.mapView.trailLayersManager.setVisibleTrails(trailIds: visibleTrails)
            }
        }
    }

    /// Checks if overlay is cached and prompts user to download the overlay.
    func checkOverlayMapCache() throws {
        let status = try OfflineMapManager.shared.getOverlayOfflineMap()?.status ?? .NOT_CACHED
        
        if status == .NOT_CACHED || status == .FAILED {
            let estimatedBytes: Int64 = (try? OfflineMapManager.shared.estimateOverlayCacheSize().totalSize) ?? 0
            AlertUtils.showPrompt(viewController: self, title: "Download", message: "Would you like to download Overlay map cache (~\(estimatedBytes.humanFileSize()))?", confirmHandler: {
                
                // Starts download of the OVERLAY chache.

                OfflineMapManager.shared.downloadOverlayOfflineMap(includeImagery: true) { result in
                    if case let .failure(error) = result {
                        // When download fails the callback is called with error reason
                        self.showError(error)
                    } else {
                        // download started, the progress delegate is notified automatically
                    }
                }
            })
        }
    }
}

// MARK:- TrailLayersManagerDelegate extension
extension DiscoverViewController : TrailLayersManagerDelegate {
    func onLayersAdded(trailLayers: Array<TrailLayerType>) {
        isTrailsLayerManagersLoaded = true
    }
}

// MARK:- MLNMapViewDelegate extension
extension DiscoverViewController : MLNMapViewDelegate {

    func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
        if self.initLoading == true && self.mapWasLoaded == true {
            self.initLoading = false
        }
    }
    
    func mapView(_ mapView: MLNMapView, didChange mode: MLNUserTrackingMode, animated: Bool) {
        if mode == .none {
            
        }
    }
    
    func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: Error) {
        showError(error)
    }
}

// MARK:- TrailListViewDelegate extension
extension DiscoverViewController : TrailListViewDelegate {
    func showInfo(_ text: String) {
        
    }
    
    func didTapTrailInfo(basicInfo: TrailBasicInfo) {
        self.showTrailPOIs(trailId: basicInfo.id)
        tryOrShowError {
            try self.mapView.trailLayersManager.highLightTrail(trailId: basicInfo.id)
        }
        self.trailsListView.selectTrail(trailId: basicInfo.id)
        onLoadTrailDetail(basicInfo: basicInfo)
    }

    func didTapTrailMap(basicInfo: TrailBasicInfo) {
        do {
            self.showTrailPOIs(trailId: basicInfo.id)
            try self.mapView.trailLayersManager.highLightTrail(trailId: basicInfo.id)
            if let trailManager = self.trailService,
                let trail = try trailManager.getTrailById(basicInfo.id) {
                self.zoomToTrail(locationInfo: trail.locationInfo)
            }
        }
        catch {
            Log.e(TAG, error)
        }
    }
    
    func didSelectTrail(basicInfo: TrailBasicInfo) {
        self.showTrailPOIs(trailId: basicInfo.id)
        tryOrShowError {
            try self.mapView.trailLayersManager.highLightTrail(trailId: basicInfo.id)
        }
    }
    
    private func showTrailPOIs(trailId: Int64?) {
        if let trailId = trailId {
            tryOrShowError {
                if let trailManager = self.trailService,
                    let trail = try trailManager.getTrailById(trailId) {
                    self.mapView.trailLayersManager.showTrailPOIs(trail: trail)
                }
            }
        } else {
            self.mapView.trailLayersManager.hideAllTrailPOIs()
        }
    }
    
    func toggleTrailListPosition() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            if self.trailListSliderMode == .closed {
                self.showTrailListPartialMode()
            }
            else if self.trailListSliderMode == .partial {
                self.showTrailListFullMode()
            }
            else if self.trailListSliderMode == .full {
                self.showTrailListClosedMode()
            }
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func showTrailListFullMode() {
        self.trailListSliderMode = .full
        self.listViewHeightFullConstraint.isActive = true
        self.trailsListView.listButton.setImage(UIImage.chevronDownImage, for: .normal)
    }
    
    func showTrailListPartialMode() {
        self.trailListSliderMode = .partial
        self.mapViewHeightClosedConstraint.isActive = false
        self.listViewHeightFullConstraint.isActive = false
        self.trailsListView.listButton.setImage(UIImage.chevronUpImage, for: .normal)
    }
    
    func showTrailListClosedMode() {
        self.trailListSliderMode = .closed
        self.listViewHeightFullConstraint.isActive = false
        self.mapViewHeightClosedConstraint.isActive = true
        self.trailsListView.listButton.setImage(UIImage.chevronUpImage, for: .normal)
    }
    
    func getVisibleMapCenter() -> MapLocation {
        let center = self.mapView.camera.centerCoordinate
        return MapLocation(latitude: center.latitude, longitude: center.longitude)
    }
    
    func getMapBounds() throws -> MapBounds {
        let visibleRegion = self.mapView.visibleCoordinateBounds
        
        return try MapBounds(
            minLat: max(visibleRegion.sw.latitude, -90),
            minLon: max(visibleRegion.sw.longitude, -180),
            maxLat: min(visibleRegion.ne.latitude, 90),
            maxLon: min(visibleRegion.ne.longitude, 180))
    }
    
    func handleMapViewChanged() {
        refreshTrailListByMapBoundFilter()
    }
    
    func reloadLayers() {
        tryOrShowError {
            try mapView.trailLayersManager.reloadLayers()
        }
    }
}

// MARK:- TrailInfoViewDelegate extension
extension DiscoverViewController : TrailInfoViewDelegate {
    func didTapTrailInfoBackButton() {
        self.cacheProgressView.isHidden = true
        self.cacheProgressHeightConstraint.constant = 0
    }
}

// MARK:- UISearchBarDelegate extension
extension DiscoverViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        setUpSearchBar()
        showTrailListPartialMode()
        self.searchController?.dismiss(animated: true, completion: nil)
        self.searchController = nil
        setTrailNameFilter(trailNameFilter: nil)
        self.taskBar?.isUserInteractionEnabled = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setUpSearchBar()
        showTrailListPartialMode()
        self.searchController?.dismiss(animated: true, completion: nil)
        self.searchController = nil
        setTrailNameFilter(trailNameFilter: searchBar.text)
        self.taskBar?.isUserInteractionEnabled = true
    }
}

// MARK:- FilterViewControllerDelegate extension
extension DiscoverViewController : FilterViewControllerDelegate {
    func applyFilter(trailsFilter: TrailsFilter) {
        self.trailsFilter = trailsFilter
        let visibleTrails = self.trailsListView.loadTrails()
        self.mapView.trailLayersManager.setVisibleTrails(trailIds: visibleTrails)
    }
}

// MARK:- CacheProgressDelegate extension
extension DiscoverViewController : CacheProgressDelegate {
    func onProgressChanged(offlineMap: IOfflineMap) {
        
        // This method is called when download progress changes for either trail or overlay cache
        // Progress value is from 0.0 to 1.0
        let progress = offlineMap.progress
        
        self.cacheProgressView.isHidden = false
        self.cacheProgressHeightConstraint.constant = 30
        self.cacheProgressView.progress = Float(progress)
        switch offlineMap.type {
        case .OVERLAY:
            self.cacheProgressView.text = "Downloading \(offlineMap.displayName): \(Int(progress * 100))%"
        case .TRAIL:
            self.cacheProgressView.text = "Downloading \(offlineMap.displayName): \(Int(progress * 100))%"
        case .AREA:
            self.cacheProgressView.text = "Downloading \(offlineMap.displayName): \(Int(progress * 100))%"
        }
    }
    
    func onError(error: [OfflineResourceError], offlineMap: IOfflineMap) {
        
        // When download fails the onError is called first followed by onComplete
        
        let message = error.map ({ (resourceError) -> String in
            return "\(resourceError.offlineResource.getResourceTypeName()) failed \(resourceError.error)"
        }).joined(separator: "\n")
        showError(message.toError())
        self.cacheProgressView.isHidden = true
        self.cacheProgressHeightConstraint.constant = 0
    }
    
    func onComplete(offlineMap: IOfflineMap) {
        self.cacheProgressView.isHidden = true
        self.cacheProgressHeightConstraint.constant = 0
    }
    
    func onImageryDeleted(offlineMaps: [IOfflineMap]) {
        let offlineMapNames = offlineMaps.map { $0.displayName }.joined(separator: "\n")
        AlertUtils.showAlert(viewController: self, title: "Imagery deleted", message: "Because of HERE maps compliance, imagery were deleted from following offline maps: \n\(offlineMapNames)")
    }
}
