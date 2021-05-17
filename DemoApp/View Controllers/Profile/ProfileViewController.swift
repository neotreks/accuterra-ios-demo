//
//  ProfileViewController.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/18/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class ProfileViewController: BaseViewController {

    // MARK:- Properties
    private let TAG = "ProfileViewController"

    // MARK:- Lifecycle
    override func viewDidLoad() {
        self.title = "User Profile"
        super.viewDidLoad()
    }
    
    // MARK:- Actions
    
    @IBAction func didTapSettings() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "Settings") as? SettingsViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func didTapResetToken() {
        DemoAccessManager.shared.resetToken { () in
            executeBlockOnMainThread {
                self.showInfo("Token reset")
            }
        } errorHandler: { (error) in
            executeBlockOnMainThread {
                self.showError(error)
            }
        }
    }
    
    @IBAction func didTapDownloadOfflineMaps() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "OfflineMaps") as? OfflineMapsViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func didTapDbPasscode() {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: "DbPasscodeVC") as? DbPasscodeViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
