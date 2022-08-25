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

    @IBOutlet weak var versionLabel: UILabel!

    // MARK:- Lifecycle
    override func viewDidLoad() {
        self.title = "User Profile"

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let environment = Bundle.main.infoDictionary?["AccuTerraEnvironment"] as? String {
            self.versionLabel.text = "\(version) - \(environment)"
        }

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
        DemoCredentialsAccessManager.shared.resetToken { () in
            executeBlockOnMainThread {
                self.showInfo("Token reset")
            }
        } errorHandler: { (error) in
            executeBlockOnMainThread {
                self.showError(error)
            }
        }
    }
    
    @IBAction func didTapDeleteUserData() {
        let actionSheet =
            UIAlertController(
                title: "Delete User Data?",
                message: "User data will be deleted from this device. This operation cannot be undone.",
                preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            self.deleteUserDataImpl()
        }))

        self.present(actionSheet, animated: true)
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

    private func deleteUserDataImpl() {
        guard let progress = AlertUtils.buildBlockingProgressValueDialog() else {
            return
        }
        progress.style = .loadingIndicator
        progress.title = "Deleting User Data"
        present(progress, animated: false) {
            DispatchQueue.global().async {
                SdkManager.shared.deleteUserData(onComplete: { result in
                    executeBlockOnMainThread {
                        progress.dismiss(animated: false) {
                            if result.hasErrors() {
                                self.showError(result.toString().toError())
                            } else {
                                self.showInfo("User data deleted successfully")
                            }
                        }
                    }
                },
                onError: { error in
                    executeBlockOnMainThread {
                        progress.dismiss(animated: false) {
                            self.showError(error)
                        }
                    }
                })
            }
        }
    }
}
