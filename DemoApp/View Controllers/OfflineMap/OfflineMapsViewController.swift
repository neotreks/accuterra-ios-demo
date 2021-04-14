//
//  OfflineMapsViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 18.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class OfflineMapsViewController: BaseViewController {

    // MARK:- Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK:- Properties
    private let TAG = "OfflineMapsViewController"
    var refreshControl = UIRefreshControl()
    lazy var listItems = [IOfflineMap]()
    var canRefresh = true
    
    // MARK:- Lifecycle
    override func viewDidLoad() {
        self.title = "Offline Maps"
        super.viewDidLoad()
        
        OfflineMapManager.shared.addProgressObserver(observer: self)
        
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    deinit {
        OfflineMapManager.shared.removeProgressObserver(observer: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadOfflineMaps()
    }
    
    @objc private func refresh(sender:AnyObject) {
        loadOfflineMaps()
    }

    @IBAction func didTapNewMapButton() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "NewOfflineMap") as? NewOfflineMapViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK:- Loaders
    func loadOfflineMaps() {
        self.refreshControl.beginRefreshing()
        
        tryOrShowError {
            self.listItems = try OfflineMapManager.shared.getOfflineMaps()
        }
        
        self.reloadTableData()
    }

    func reloadTableData() {
        self.refreshControl.endRefreshing()
        self.tableView.reloadData()
    }
}

// MARK:- Table view extensions

extension OfflineMapsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.refreshControl.isRefreshing {
            return 0
        } else {
            if self.listItems.count == 0 {
                return 1
            } else {
                return self.listItems.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.listItems.count == 0 {
            // empty cell height
            return tableView.frame.height
        } else {
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.listItems.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "offlineMapTableEmptyViewCell", for: indexPath)
        } else {
            let item = self.listItems[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "offlineMapTableViewCell", for: indexPath) as! OfflineMapTableViewCell
            cell.delegate = self
            cell.bindView(offlineMap: item)
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
}

// MARK:- Cache progress extension

extension OfflineMapsViewController : CacheProgressDelegate {
    func onProgressChanged(offlineMap: IOfflineMap) {
        if let itemIndex = self.listItems.firstIndex(where: { (item) -> Bool in
            return item.offlineMapId == offlineMap.offlineMapId
        }) {
            self.listItems[itemIndex] = offlineMap
            self.tableView.reloadRows(at: [IndexPath(row: itemIndex, section: 0)], with: .none)
        } else {
            // item not found, reload
            loadOfflineMaps()
        }
    }
    
    func onError(error: [OfflineResourceError], offlineMap: IOfflineMap) {
        if let itemIndex = self.listItems.firstIndex(where: { (item) -> Bool in
            return item.offlineMapId == offlineMap.offlineMapId
        }) {
            self.listItems[itemIndex] = offlineMap
            self.tableView.reloadRows(at: [IndexPath(row: itemIndex, section: 0)], with: .none)
        } else {
            // item not found, reload
            loadOfflineMaps()
        }
        
        if offlineMap.status != .CANCELED {
            let errorMessage = error.map({ (it) -> String in
                "\(it.offlineResource.getResourceTypeName()): \(it.error)"
            }).joined(separator: ",")
            showError("Download failed: \(errorMessage)".toError())
        }
    }
    
    func onComplete(offlineMap: IOfflineMap) {
        if let itemIndex = self.listItems.firstIndex(where: { (item) -> Bool in
            return item.offlineMapId == offlineMap.offlineMapId
        }) {
            self.listItems[itemIndex] = offlineMap
            self.tableView.reloadRows(at: [IndexPath(row: itemIndex, section: 0)], with: .none)
        } else {
            // item not found, reload
            loadOfflineMaps()
        }
    }
}

// MARK:- OfflineMapTableViewCellDelegate extension

extension OfflineMapsViewController: OfflineMapTableViewCellDelegate {
    func showContextMenu(offlineMapId: String) {
        tryOrShowError {
            if let offlineMap = try OfflineMapManager.shared.getOfflineMap(offlineMapId: offlineMapId) {
                
                let actionController = UIAlertController(title: "Saved Map", message: nil, preferredStyle: .actionSheet)
                
                let updateAction = UIAlertAction(title: "Update", style: .default, handler: { (action) in
                    self.updateOfflineMap(offlineMap: offlineMap)
                })
                
                let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action) in
                    self.editOfflineMap(offlineMap: offlineMap)
                })
                
                let renameAction = UIAlertAction(title: "Rename", style: .default, handler: { (action) in
                    self.renameOfflineMap(offlineMap: offlineMap)
                })
                
                let cancelAction = UIAlertAction(title: "Cancel Download", style: .default, handler: { (action) in
                    self.showCancelPrompt(offlineMap: offlineMap)
                })
                
                let deleteAction = UIAlertAction(title: "Delete", style: .default, handler: { (action) in
                    self.showDeletePrompt(offlineMap: offlineMap)
                })
                
                let resumeAction = UIAlertAction(title: "Resume", style: .default, handler: { (action) in
                    self.resumeDownload(offlineMap: offlineMap)
                })
                
                let pauseAction = UIAlertAction(title: "Pause", style: .default, handler: { (action) in
                    self.pauseDownload(offlineMap: offlineMap)
                })
                
                // Check offline map state and fill options accordingly
                switch offlineMap.status {
                case .FAILED:
                    actionController.addAction(deleteAction)
                case .IN_PROGRESS:
                    actionController.addAction(cancelAction)
                    actionController.addAction(pauseAction)
                case .COMPLETE:
                    actionController.addAction(updateAction)
                    if offlineMap.type == .AREA {
                        actionController.addAction(renameAction)
                        actionController.addAction(editAction)
                    }
                    actionController.addAction(deleteAction)
                case .WAITING:
                    actionController.addAction(cancelAction)
                case .NOT_CACHED:
                    actionController.addAction(cancelAction)
                case .PAUSED:
                    actionController.addAction(resumeAction)
                    actionController.addAction(cancelAction)
                case .CANCELED:
                    break
                }
                
                actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    actionController.dismiss(animated: true, completion: nil)
                }))
                
                present(actionController, animated: false)
                // prevent constraings bug in iOS
                actionController.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint)-> (Bool)  in
                    return (one.constant < 0) && (one.secondItem == nil) &&  (one.firstAttribute == .width)
                }.first?.isActive = false
            } else {
                // Item not found, reload table
                loadOfflineMaps()
            }
        }
    }
    
    /// Removes current offline map and creates it again
    private func updateOfflineMap(offlineMap: IOfflineMap) {
        tryOrShowError {
            let progressDialog = AlertUtils.buildBlockingProgressValueDialog()!
            progressDialog.style = .loadingIndicator
            progressDialog.title = "Updating Offline Map"
            
            self.present(progressDialog, animated: false) {
                OfflineMapManager.shared.deleteOfflineMap(offlineMapId: offlineMap.offlineMapId) {
                    // Download it again
                    switch offlineMap.type {
                    case .AREA:
                        if let areaOfflineMap = offlineMap as? IAreaOfflineMap {
                            OfflineMapManager.shared.downloadAreaOfflineMap(
                                bounds: areaOfflineMap.bounds,
                                areaName: areaOfflineMap.areaName,
                                includeImagery: areaOfflineMap.containsImagery) { (newMap) in
                                
                                executeBlockOnMainThread {
                                    progressDialog.dismiss(animated: false, completion: nil)
                                    self.loadOfflineMaps()
                                }
                            } errorHandler: { (error) in
                                executeBlockOnMainThread {
                                    progressDialog.dismiss(animated: false, completion: nil)
                                    self.showError(error)
                                }
                            }
                        }
                    case .OVERLAY:
                        OfflineMapManager.shared.downloadOverlayOfflineMap { (newMap) in
                            executeBlockOnMainThread {
                                progressDialog.dismiss(animated: false, completion: nil)
                                self.loadOfflineMaps()
                            }
                        } errorHandler: { (error) in
                            executeBlockOnMainThread {
                                progressDialog.dismiss(animated: false, completion: nil)
                                self.showError(error)
                            }
                        }
                    case .TRAIL:
                        if let trailOfflineMap = offlineMap as? ITrailOfflineMap {
                            OfflineMapManager.shared.downloadTrailOfflineMap(
                                trailId: trailOfflineMap.trailId) { (newMap) in
                                
                                executeBlockOnMainThread {
                                    progressDialog.dismiss(animated: false, completion: nil)
                                    self.loadOfflineMaps()
                                }
                            } errorHandler: { (error) in
                                executeBlockOnMainThread {
                                    progressDialog.dismiss(animated: false, completion: nil)
                                    self.showError(error)
                                }
                            }
                        }
                    }
                } errorHandler: { (error) in
                    progressDialog.dismiss(animated: false, completion: nil)
                    self.showError(error)
                }
            }
        }
    }
    
    private func editOfflineMap(offlineMap: IOfflineMap) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "NewOfflineMap") as? NewOfflineMapViewController {
            vc.editOfflineMapId = offlineMap.offlineMapId
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func renameOfflineMap(offlineMap: IOfflineMap) {
        guard let areaOfflineMap = offlineMap as? IAreaOfflineMap else {
            return
        }
        
        let alert = UIAlertController(title: "Rename Offline Map", message: "", preferredStyle: .alert)
        var nameTextField: UITextField? = nil
        alert.addTextField { (textField) in
            nameTextField = textField
        }
        alert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { (action) in
            if let text = nameTextField?.text, text.count > 0 {
                alert.dismiss(animated: false) { () in
                    self.tryOrShowError {
                        let _ = try OfflineMapManager.shared.renameAreaOfflineMap(offlineMap: areaOfflineMap, areaName: text)
                        self.loadOfflineMaps()
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // nothing to do
        }))
        present(alert, animated: false, completion: nil)
    }
    
    private func showCancelPrompt(offlineMap: IOfflineMap) {
        AlertUtils.showPrompt(viewController: self, title: "Cancel Download", message: "Do you really want to cancel download \(getOfflineMapName(offlineMap: offlineMap))?") {
            self.deleteOfflineMap(offlineMapId: offlineMap.offlineMapId)
        }
    }
    
    private func showDeletePrompt(offlineMap: IOfflineMap) {
        AlertUtils.showPrompt(viewController: self, title: "Delete Download", message: "Do you really want to delete offline map \(getOfflineMapName(offlineMap: offlineMap))?") {
            self.deleteOfflineMap(offlineMapId: offlineMap.offlineMapId)
        }
    }
    
    private func resumeDownload(offlineMap: IOfflineMap) {
        tryOrShowError {
            try OfflineMapManager.shared.resume()
            loadOfflineMaps()
        }
    }
    
    private func pauseDownload(offlineMap: IOfflineMap) {
        tryOrShowError {
            try OfflineMapManager.shared.pause()
            loadOfflineMaps()
        }
    }
    
    private func deleteOfflineMap(offlineMapId: String) {
        let progressDialog = AlertUtils.buildBlockingProgressValueDialog()!
        progressDialog.style = .loadingIndicator
        progressDialog.title = "Canceling Download"
        self.present(progressDialog, animated: false) {
            OfflineMapManager.shared.deleteOfflineMap(offlineMapId: offlineMapId) {
                executeBlockOnMainThread {
                    self.loadOfflineMaps()
                    progressDialog.dismiss(animated: false, completion: nil)
                }
            } errorHandler: { (error) in
                progressDialog.dismiss(animated: false, completion: nil)
                self.showError(error)
            }
        }
    }
    
    private func getOfflineMapName(offlineMap: IOfflineMap) -> String {
        switch offlineMap.type {
        case  .AREA:
            return (offlineMap as? IAreaOfflineMap)?.areaName ?? offlineMap.offlineMapId
        case .OVERLAY:
            return "OVERLAY"
        case .TRAIL:
            return "TRAIL \((offlineMap as? ITrailOfflineMap)?.trailName ?? offlineMap.offlineMapId)"
        }
    }
}
