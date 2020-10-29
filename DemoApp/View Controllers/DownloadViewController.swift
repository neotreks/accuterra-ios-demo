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
    @IBOutlet weak var progressTitle: UILabel!
    @IBOutlet weak var progressValue: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        self.view.alpha = 0
        super.viewDidLoad()
    }
    
    weak var delegate: DownloadViewControllerDelegate?
    
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
        guard let serviceUrl = Bundle.main.infoDictionary?["WS_BASE_URL"] as? String else {
                fatalError("WS_BASE_URL is missing in info.plist")
        }
        guard let accuTerraMapStyleUrl = Bundle.main.infoDictionary?["ACCUTERRA_MAP_STYLE_URL"] as? String else {
            fatalError("ACCUTERRA_MAP_STYLE_URL is missing in info.plist")
        }
        SdkManager.shared.initSdkAsync(config: SdkConfig(wsUrl: serviceUrl, accuterraMapStyleUrl: accuTerraMapStyleUrl), accessProvider: DemoAccessManager.shared, delegate: self)
    }
}

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
                default:
                    self.progressTitle.text = "Downloading ... "
                }
            default:
                break
            }
        }
    }
}
