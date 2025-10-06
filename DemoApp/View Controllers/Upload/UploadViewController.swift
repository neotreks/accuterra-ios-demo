//
//  UploadViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 30.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Combine

class UploadViewController: BaseViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var tripUuid: String?
    var versionUUid: String?
    var refreshControl = UIRefreshControl()
    private lazy var requests = [UploadRequest]()
    var canRefresh = true
    private var documentInteractionController: UIDocumentInteractionController?
    private var cancellable: Cancellable?
    
    // MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancellable = NotificationCenter.default
            .publisher(for: UploadRequestNotificationName)
            .sink() {[weak self] notification in
                self?.statusChanged(notification: notification)
            }
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        setUpNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRequests()
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
            if FileManager.default.fileExists(atPath: exportFolder.path) {
                try FileManager.default.removeItem(atPath: exportFolder.path)
            }
            try FileManager.default.createDirectory(at: exportFolder, withIntermediateDirectories: true, attributes: nil)
            
            try requests.forEach { (request) in
                if let dataPath = request.dataPath {
                    let fileUrl = URL(fileURLWithPath: dataPath, isDirectory: false)
                    switch request.dataType {
                    case .TRIP:
                        // fileUrl contains path to zip, we want to extract it into the export folder
                        try IOUtils.unzipFile(fileUrl: fileUrl, toDestination: exportFolder)

                        // Copy trip db
                        let tripDbFolder = exportFolder.appendingPathComponent("db", isDirectory: true)
                        try FileManager.default.createDirectory(at: tripDbFolder, withIntermediateDirectories: true, attributes: nil)

                        let tripDb = AccuTerraFiles.AccuTerraLibraryDirectory.appendingPathComponent("accuterra-sdk-trip.db", isDirectory: false)
                        let tripDbShm = AccuTerraFiles.AccuTerraLibraryDirectory.appendingPathComponent("accuterra-sdk-trip.db-shm", isDirectory: false)
                        let tripDbWal = AccuTerraFiles.AccuTerraLibraryDirectory.appendingPathComponent("accuterra-sdk-trip.db-wal", isDirectory: false)
                        let sdkDb = AccuTerraFiles.AccuTerraLibraryDirectory.appendingPathComponent("accuterra-sdk.db", isDirectory: false)
                        let sdkDbShm = AccuTerraFiles.AccuTerraLibraryDirectory.appendingPathComponent("accuterra-sdk.db-shm", isDirectory: false)
                        let sdkDbWal = AccuTerraFiles.AccuTerraLibraryDirectory.appendingPathComponent("accuterra-sdk.db-wal", isDirectory: false)

                        try? FileManager.default.copyItem(at: tripDb, to: tripDbFolder.appendingPathComponent("accuterra-sdk-trip.db", isDirectory: false))
                        try? FileManager.default.copyItem(at: tripDbShm, to: tripDbFolder.appendingPathComponent("accuterra-sdk-trip.db-shm", isDirectory: false))
                        try? FileManager.default.copyItem(at: tripDbWal, to: tripDbFolder.appendingPathComponent("accuterra-sdk-trip.db-wal", isDirectory: false))
                        try? FileManager.default.copyItem(at: sdkDb, to: tripDbFolder.appendingPathComponent("accuterra-sdk.db", isDirectory: false))
                        try? FileManager.default.copyItem(at: sdkDbShm, to: tripDbFolder.appendingPathComponent("accuterra-sdk.db-shm", isDirectory: false))
                        try? FileManager.default.copyItem(at: sdkDbWal, to: tripDbFolder.appendingPathComponent("accuterra-sdk.db-wal", isDirectory: false))
                    default:
                        let attachmentsFolder = exportFolder.appendingPathComponent("attachments")
                        // fileUrl contains path to attachment, we want to copy it into attachments folder, but we need to watch for multipart attachments

                        if let startIndex = request.multipartStartIndex, let endIndex = request.multipartEndIndex {
                            let fileExtension = fileUrl.pathExtension
                            let tempFileName = "\(request.dataUuid).\(fileExtension)"
                            let tempCopy = attachmentsFolder.appendingPathComponent(tempFileName, isDirectory: false)
                            if FileManager.default.fileExists(atPath: tempCopy.path) {
                                try FileManager.default.removeItem(at: tempCopy)
                            }
                            let multipartData: Data = try readBytes(file: fileUrl, startIndex: startIndex, endIndex: endIndex)
                            try multipartData.write(to: tempCopy)
                        } else {
                            let tempCopy = attachmentsFolder.appendingPathComponent(fileUrl.lastPathComponent, isDirectory: false)
                            if FileManager.default.fileExists(atPath: tempCopy.path) {
                                try FileManager.default.removeItem(at: tempCopy)
                            }
                            try FileManager.default.copyItem(at: fileUrl, to: tempCopy)
                        }
                    }

                }
            }
            
            let zipPath = tempFolder.appendingPathComponent("export\(tripUuid).zip", isDirectory: false)
            if FileManager.default.fileExists(atPath: zipPath.path) {
                try FileManager.default.removeItem(at: zipPath)
            }

            try IOUtils.zipFolder(folder: exportFolder, zipFile: zipPath)
            
            self.documentInteractionController = UIDocumentInteractionController(url: zipPath)
            self.documentInteractionController?.presentOpenInMenu(from: self.view.frame, in: self.view, animated: true)
        }
    }

    /// Read file bytes from given [startIndex] to [endIndex]
    private func readBytes(file: URL, startIndex: Int64, endIndex: Int64) throws -> Data {
        if !FileManager.default.fileExists(atPath: file.path) {
            throw "File does not exits: \(file.path)".toError()
        }

        guard let fileHandle: FileHandle = FileHandle(forReadingAtPath: file.path) else {
            throw "Cannot read file \(file.path)".toError()
        }

        fileHandle.seek(toFileOffset: UInt64(startIndex))
        let data = fileHandle.readData(ofLength: Int(1 + endIndex - startIndex))
        fileHandle.closeFile()
        return data
    }
    
    private func statusChanged(notification: Notification) {
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
            self.requests = try service.getUploadRequestsForObject(objectUUID: tripUuid, versionUuid: versionUUid)
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
Last attempt date: \(lastUploadAttemptDate?.toIsoDateTimeString() ?? "--")
Next attempt min. date: \(nextAttemptMinDate?.toIsoDateTimeString() ?? "--")
Upload date: \(uploadDate?.toIsoDateTimeString() ?? "--")
Error: \(error ?? "--")
------
Data path: \(dataPath ?? "--")
"""
    }
}
