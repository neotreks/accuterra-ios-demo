//
//  DownloadViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 21/02/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit
import AccuTerraSDK

protocol DownloadViewControllerDelegate: SdkInitDelegate {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool)
}

class DownloadViewController : BaseViewController {
    // MARK:- IBOutlets
    @IBOutlet weak var progressTitle: UILabel!
    @IBOutlet weak var progressValue: UILabel!
    @IBOutlet weak var progressView: UIProgressView!

    // MARK:- Properties
    weak var delegate: DownloadViewControllerDelegate?

    // MARK:- Lifecycle
    override func viewDidLoad() {
        self.view.alpha = 0
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let dialog = UIAlertController(title: "Download", message: "The trail DB is going to be downloaded now.", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            self.view.alpha = 1
            self.initSdk()
        }))
        delegate?.present(dialog, animated: true)
    }
    
    private func initSdk() {
        SdkManager.shared.initSdkAsync(config: demoAppSdkConfig, accessProvider: DemoCredentialsAccessManager.shared, identityProvider: DemoIdentityManager.shared, delegate: self, dbEncryptConfigProvider: DemoDbEncryptProvider())
    }
}

// MARK:- SdkInitDelegate extension
extension DownloadViewController : SdkInitDelegate {
    func onProgressChanged(progress: Int) {
        DispatchQueue.main.async {
            self.progressView.progress = Float(progress) / 100.0
            self.progressValue.text = "\(progress)%"
        }
    }
    
    func onStateChanged(state: SdkInitState, detail: SdkInitStateDetail?) {
        self.delegate?.onStateChanged(state: state, detail: detail)
        executeBlockOnMainThread {
            switch state {
            case .IN_PROGRESS:
                switch detail ?? .TRAIL_DB_DOWNLOAD {
                case .TRAIL_DB_UNPACK:
                    self.progressTitle.text = "Extracting"
                    self.progressValue.text = ""
                case .TRAIL_MARKERS_CACHE_INIT:
                    self.progressTitle.text = "Initializing Trail Markers Cache ... "
                case .TRAIL_PATHS_CACHE_INIT:
                    self.progressTitle.text = "Initializing Trail Paths Cache ... "
                case .TRAIL_USER_DATA_UPDATE:
                    self.progressTitle.text = "Updating User data ..."
                case .TRAIL_DYNAMIC_DATA_UPDATE:
                    self.progressTitle.text = "Updating Trail Dynamic Data"
                case .TRAIL_DB_UPDATE:
                    self.progressTitle.text = "Updating Trail DB ..."
                case .TRAIL_DB_DOWNLOAD:
                    self.progressTitle.text = "Downloading ... "
                }
            default:
                break
            }
        }
    }
}
