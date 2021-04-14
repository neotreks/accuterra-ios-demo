//
//  TrailListView.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 20/12/2019.
//  Copyright © 2019 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

protocol TrailListViewDelegate : class {
    func didTapTrailInfo(basicInfo: TrailBasicInfo)
    func didTapTrailMap(basicInfo: TrailBasicInfo)
    func didSelectTrail(basicInfo: TrailBasicInfo)
    func toggleTrailListPosition()
    func reloadLayers()
    func handleMapViewChanged()
    
    // For filtering purpose
    func getVisibleMapCenter() -> MapLocation
    var trailsFilter: TrailsFilter { get }
    
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
    func showInfo(_ text: String)
    func showError(_ error: Error)
}

class TrailListView: UIView {

    private let TAG = "TrailListView"
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var listButton: UIButton!
    
    var trailsService: ITrailService?
    
    weak var delegate: TrailListViewDelegate?
    
    var trails: Array<TrailBasicInfo>?
    
    private var selectedTrailId: Int64?
    
    func loadTrails() -> Set<Int64> {
        tableView.register(UINib(nibName: TrailListTableviewCell.cellXibName, bundle: nil), forCellReuseIdentifier: TrailListTableviewCell.cellIdentifier)
        guard let delegate = self.delegate else {
            Log.e(TAG, "TrailListView delegate not set")
            return Set<Int64>()
        }
        guard SdkManager.shared.isTrailDbInitialized else {
            return Set<Int64>()
        }
        let filter = delegate.trailsFilter
        // Note: when searching by name, we disable other filters
        let hasTrailNameFilter = filter.trailNameFilter != nil
        do {
            if self.trailsService == nil {
                trailsService = ServiceFactory.getTrailService()
            }
            
            var techRatingSearchCriteria: ITechRatingSearchCriteria?
            if let maxDifficultyLevel = filter.maxDifficulty?.level, !hasTrailNameFilter {
                techRatingSearchCriteria = TechRatingSearchCriteriaBuilder.build(
                    level: maxDifficultyLevel,
                    comparison: Comparison.lessEquals)
            }
            
            var userRatingSearchCriteria: IUserRatingSearchCriteria?
            if let minUserRating = filter.minUserRating, !hasTrailNameFilter {
                userRatingSearchCriteria = UserRatingSearchCriteriaBuilder.build(
                    userRating: Float(minUserRating),
                    comparison: .greaterEquals
                )
            }
            
            var lengthSearchCriteria: LengthSearchCriteria?
            if let maxTripDistance = filter.maxTripDistance, !hasTrailNameFilter{
                lengthSearchCriteria = LengthSearchCriteria(length: Double(maxTripDistance))
            }
            
            if let mapBounds = filter.boundingBoxFilter, !hasTrailNameFilter {
                let searchCriteria = TrailMapBoundsSearchCriteria(
                    mapBounds: mapBounds,
                    nameSearchCriteria: nil,
                    techRating: techRatingSearchCriteria,
                    userRating: userRatingSearchCriteria,
                    length: lengthSearchCriteria,
                    orderBy: OrderByBuilder.build(),
                    limit: QueryLimitBuilder.build())
                self.trails = try trailsService!.findTrails(byMapBoundsCriteria: searchCriteria)
                self.tableView.reloadData()
            } else {
                let searchCriteria = TrailMapSearchCriteria(
                    mapCenter: delegate.getVisibleMapCenter(),
                    nameSearchCriteria: TextSearchCriteriaBuilder.build(searchString: filter.trailNameFilter!),
                    techRating: techRatingSearchCriteria,
                    userRating: userRatingSearchCriteria,
                    length: lengthSearchCriteria,
                    orderBy: OrderByBuilder.build(),
                    limit: QueryLimitBuilder.build())
                self.trails = try trailsService!.findTrails(byMapCriteria: searchCriteria)
                self.tableView.reloadData()
            }
            self.selectTrail(trailId: self.selectedTrailId)
        }
        catch {
            Log.e(TAG, error)
            (delegate as? UIViewController)?.showError(error)
        }
        
        if let filteredTrailIds = self.trails?.map({ (trail) -> Int64 in
            return trail.id
        }) {
            return Set<Int64>(filteredTrailIds)
        } else {
            return Set<Int64>()
        }
    }
    
    func selectTrail(trailId: Int64?) {
        self.selectedTrailId = trailId
        guard let trailId = trailId else {
            self.tableView.selectRow(at: nil, animated: false, scrollPosition: UITableView.ScrollPosition.none)
            return
        }
        if let trails = self.trails, let index = trails.firstIndex(where: { (t) -> Bool in
            return t.id == trailId
        }) {
            self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.none)
        }
    }

    @IBAction func didTapOnListShow(_ sender: Any) {
        delegate?.toggleTrailListPosition()
    }
    
    @IBAction func didTapDownloadUpdates(_ sender: Any) {
        guard let delegate = self.delegate, let dialog = AlertUtils.buildBlockingProgressValueDialog() else {
            return
        }
        dialog.title = "Updating Trail DB"
        delegate.present(dialog, animated: false, completion: nil)
        
        let service = ServiceFactory.getTrailService()
        do {
            try service.updateTrailDb { (progress) in
                dialog.progress = Float(progress.fractionCompleted)
            } callback: { result in
                if result.value?.hasChangeActions() == true {
                    delegate.reloadLayers()
                    delegate.handleMapViewChanged()
                }
                dialog.dismiss(animated: false, completion: nil)
                if result.isSuccess {
                    if result.value?.hasChangeActions() == true {
                        delegate.showInfo("Trail DB updated (\(result.value?.changedTrailsCount() ?? 0)).")
                    } else {
                        delegate.showInfo("There were no updates of the Trail DB.")
                    }
                } else {
                    delegate.showError("Trails update failed. \(result.buildErrorMessage() ?? "unknown")".toError())
                }
            }
        } catch {
            dialog.dismiss(animated: false, completion: nil)
            delegate.showError(error)
        }
    }
}

extension TrailListView : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.trails?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :TrailListTableviewCell = tableView.dequeueReusableCell(withIdentifier: TrailListTableviewCell.cellIdentifier, for: indexPath) as! TrailListTableviewCell
        if let trails = trails {
            TrailInfoDisplay.setDisplayFieldValues(trailTitleLabel: &cell.trailTitle, descriptionLabel:&cell.trailDescription, distanceLabel: &cell.trailDistanceLabel, userRatings: &cell.ratingStars, difficultyColorBar:&cell.difficultyColorBarLabel, basicTrailInfo: trails[indexPath.row])
            cell.trail = trails[indexPath.row]
        }
        cell.delegate = self.delegate
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let trails = self.trails else {
            return indexPath
        }
        self.delegate?.didSelectTrail(basicInfo: trails[indexPath.row])
        self.selectedTrailId = trails[indexPath.row].id
        return indexPath
    }
}

