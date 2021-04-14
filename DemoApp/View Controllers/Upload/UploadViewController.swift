//
//  UploadViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 30.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import SSZipArchive

class UploadViewController: BaseViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var tripUuid: String?
    var refreshControl = UIRefreshControl()
    private lazy var requests = [UploadRequest]()
    var canRefresh = true
    private var documentInteractionController: UIDocumentInteractionController?
    
    // MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(statusChanged(notification:)), name: UploadRequestNotificationName, object: nil)
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        setUpNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRequests()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setUpNavBar() {
        // Right button
        let buttonExport = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up.fill"), style: .done, target: self, action: #selector(self.export))
        self.navigationItem.rightBarButtonItem = buttonExport
    }
    
    @objc private func refresh(sender:AnyObject) {
        loadRequests()
    }
    
    @objc private func export() {
        guard requests.count > 0 else {
            showError("There are no trip attachments".toError())
            return
        }
        guard let tripUuid = self.tripUuid else {
            return
        }
        
        tryOrShowError {
            let tempFolder = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let exportFolder = tempFolder.appendingPathComponent("export\(tripUuid)", isDirectory: true)
            if !FileManager.default.fileExists(atPath: exportFolder.path) {
                try FileManager.default.createDirectory(at: exportFolder, withIntermediateDirectories: true, attributes: nil)
            }
            
            
            try requests.forEach { (request) in
                if let dataPath = request.dataPath {
                    let fileUrl = URL(fileURLWithPath: dataPath, isDirectory: false)
                    let tempCopy = exportFolder.appendingPathComponent(fileUrl.lastPathComponent, isDirectory: false)
                    if FileManager.default.fileExists(atPath: tempCopy.path) {
                        try FileManager.default.removeItem(at: tempCopy)
                    }
                    try FileManager.default.copyItem(at: fileUrl, to: tempCopy)
                }
            }
            
            let zipPath = tempFolder.appendingPathComponent("export\(tripUuid).zip", isDirectory: false)
            if FileManager.default.fileExists(atPath: zipPath.path) {
                try FileManager.default.removeItem(at: zipPath)
            }
            
            SSZipArchive.createZipFile(atPath: zipPath.path, withContentsOfDirectory: exportFolder.path)
            
            self.documentInteractionController = UIDocumentInteractionController(url: zipPath)
            self.documentInteractionController?.presentOpenInMenu(from: self.view.frame, in: self.view, animated: true)
        }
    }
    
    @objc func statusChanged(notification: Notification) {
        if let dict = notification.userInfo, let requestUuid = dict["requestUuid"] as? String {
            if requests.contains(where: { (r) -> Bool in
                r.uuid == requestUuid
            }) {
                loadRequests()
            }
        }
    }
    
    func reloadTableData() {
        self.refreshControl.endRefreshing()
        self.tableView.reloadData()
    }
    
    private func loadRequests() {
        guard let tripUuid = self.tripUuid else {
            return
        }
        // Load the list
        let service = ServiceFactory.getUploadService()
        tryOrShowError {
            self.requests = try service.getUploadRequestsForObject(objectUUID: tripUuid)
        }
        reloadTableData()
    }
}

// MARK: - table extensions
extension UploadViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = requests[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "uploadStatusTableViewCell") as! UploadStatusTableViewCell
        cell.bindWithRequest(request: request)
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableView(tableView, heightForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let request = requests[indexPath.row]
        let width = tableView.frame.width - 130
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.font = label.font.withSize(12)
        label.text = request.fullInfo
        label.sizeToFit()
        return label.bounds.height + 20
    }
}

extension UploadRequest {
    var fullInfo : String {
        return
            """
Data type: \(dataType)
Priority: \(priority)
UUID: \(uuid)
Data UUID: \(dataUuid)
Parent data UUID: \(parentUuid ?? "--")
------
Failed attempts: \(failedAttempts)
Last attempt date: \(lastUploadAttemptDate?.toIsoDateString() ?? "--")
Next attempt min. date: \(nextAttemptMinDate?.toIsoDateTimeString() ?? "--")
Upload date: \(uploadDate?.toIsoDateTimeString() ?? "--")
Error: \(error ?? "--")
------
Data path: \(dataPath ?? "--")
"""
    }
}
