//
//  TrailListView.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 20/12/2019.
//  Copyright © 2019 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

protocol TrailListViewDelegate : AnyObject {
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

    private let TAG = LogTag(subsystem: "ATDemoApp", category: "TrailListView")
    var listButton: UIButton = UIButton()
    @IBOutlet weak var collectionView: UICollectionView!

    var trailsService: ITrailService?
    
    weak var delegate: TrailListViewDelegate?
    
    var trails: Array<TrailBasicInfo>?
    
    private var selectedTrailId: Int64?
    
    func loadTrails() -> Set<Int64> {
        guard let collectionView = self.collectionView else { return Set<Int64>() }

        collectionView.register(UINib(nibName: TrailListTableviewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TrailListTableviewCell.cellIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clear

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 24
        layout.itemSize = CGSize(width: collectionView.bounds.width - 24, height: collectionView.bounds.height)
        let horizontalInset: CGFloat = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
        collectionView.collectionViewLayout = layout
        collectionView.isPagingEnabled = true

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
                techRatingSearchCriteria = try TechRatingSearchCriteriaBuilder.build(
                    level: maxDifficultyLevel,
                    comparison: Comparison.lessEquals)
            }
            
            var userRatingSearchCriteria: IUserRatingSearchCriteria?
            if let minUserRating = filter.minUserRating, !hasTrailNameFilter {
                userRatingSearchCriteria = try UserRatingSearchCriteriaBuilder.build(
                    userRating: Float(minUserRating),
                    comparison: .greaterEquals
                )
            }
            
            var lengthSearchCriteria: ILengthSearchCriteria?
            if let maxTripDistance = filter.maxTripDistance, !hasTrailNameFilter{
                lengthSearchCriteria = try LengthSearchCriteriaBuilder.build(length: Double(maxTripDistance))
            }
            
            if let mapBounds = filter.boundingBoxFilter, !hasTrailNameFilter {
                let searchCriteria = TrailMapBoundsSearchCriteria(
                    mapBounds: mapBounds,
                    nameSearchCriteria: nil,
                    techRating: techRatingSearchCriteria,
                    userRating: userRatingSearchCriteria,
                    length: lengthSearchCriteria,
                    orderBy: OrderByBuilder.build(),
                    limit: try QueryLimitBuilder.build(),
                    trailSearchType: .BY_TRAIL_BOUNDS)
                self.trails = try trailsService!.findTrails(byMapBoundsCriteria: searchCriteria)
                self.collectionView.reloadData()
            } else {
                let searchCriteria = TrailMapSearchCriteria(
                    mapCenter: delegate.getVisibleMapCenter(),
                    nameSearchCriteria: TextSearchCriteriaBuilder.build(searchString: filter.trailNameFilter ?? ""),
                    techRating: techRatingSearchCriteria,
                    userRating: userRatingSearchCriteria,
                    length: lengthSearchCriteria,
                    orderBy: OrderByBuilder.build(),
                    limit: try QueryLimitBuilder.build())
                self.trails = try trailsService!.findTrails(byMapCriteria: searchCriteria)
                self.collectionView.reloadData()
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
            self.collectionView.selectItem(at: nil, animated: false, scrollPosition: .left)
            return
        }
        if let trails = self.trails, let index = trails.firstIndex(where: { (t) -> Bool in
            return t.id == trailId
        }) {
            self.collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .left)
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
            service.updateTrailDb(progressChange: { progress in
                dialog.progress = Float(progress.fractionCompleted)
            }, updateConfig: TrailDbUpdateConfig()) { result in
                switch result {
                case .success(let value):
                    delegate.reloadLayers()
                    delegate.handleMapViewChanged()

                    dialog.dismiss(animated: false, completion: nil)

                    switch value {
                    case .Empty, .Fresh:
                        delegate.showInfo("There were no updates of the Trail DB.")
                    case .InProgress:
                        delegate.showInfo("Trail DB update already in progress.")
                    case .Updated(_, _ ,let creates,let updates,let deletes,let ignores):
                        delegate.showInfo("Trail DB updated creted: (\(creates.count), updated: \(updates.count), deleted: \(deletes.count), ignored: \(ignores.count)")
                    default:
                        Log.e(self.TAG, "Empty value returned for successful result: \(result)")
                    }
                case .failure(let error):
                    dialog.dismiss(animated: false, completion: nil)
                    delegate.showError(error)
                }
            }
        }
    }
}

extension TrailListView : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        trails?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrailListTableviewCell.cellIdentifier, for: indexPath) as! TrailListTableviewCell
        if let trails = trails {
            TrailInfoDisplay.setDisplayFieldValues(trailTitleLabel: &cell.trailTitle, descriptionLabel:&cell.trailDescription, distanceLabel: &cell.trailDistanceLabel, timeLabel: &cell.trailTimeLabel, elevationLabel: &cell.trailElevationLabel, userRatings: &cell.ratingStars, difficultyColorBar:&cell.difficultyColorBarLabel, difficultyLabel: &cell.difficultyLabel, difficultyView: &cell.difficultyView, bookmarkButton: cell.bookmarkButton, basicTrailInfo: trails[indexPath.row])
            cell.trail = trails[indexPath.row]
        }
        cell.delegate = self.delegate
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
}

extension TrailListView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        if let visibleIndexPath = collectionView.indexPathForItem(at: CGPoint(x: visibleRect.midX, y: visibleRect.midY)) {
            print("Current page: \(visibleIndexPath.item)")
            guard let trails = self.trails else { return }
            guard self.selectedTrailId != trails[visibleIndexPath.row].id else { return }
            self.delegate?.didSelectTrail(basicInfo: trails[visibleIndexPath.row])
            self.selectedTrailId = trails[visibleIndexPath.row].id
        }
    }
}
