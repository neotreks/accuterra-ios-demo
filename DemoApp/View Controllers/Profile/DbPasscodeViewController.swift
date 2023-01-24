//
//  DbPasscodeViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopriva on 4/07/21.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class DbPasscodeViewController: BaseViewController {

    // MARK:- Properties
    private let TAG = "DbPasscodeViewController"
    
    // MARK:- Outlets
    @IBOutlet weak var currentPasscodeTextField: UITextField!

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshPasscode()
    }
    
    // MARK:- Actions
    
    @IBAction func didTapSetPasscode() {
        let alert = UIAlertController(title: "Set Passcode", message: "Set Passcode for Trip Recording Database", preferredStyle: .alert)
        var nameTextField: UITextField? = nil
        alert.addTextField { (textField) in
            nameTextField = textField
        }
        alert.addAction(UIAlertAction(title: "Set Passcode", style: .default, handler: { (action) in
            if let text = nameTextField?.text {
                alert.dismiss(animated: false) { () in
                    self.tryOrShowError {
                        try self.changePasscode(newPasscode: text)
                        self.refreshPasscode()
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // nothing to do
        }))
        present(alert, animated: false, completion: nil)
    }
    
    private func refreshPasscode() {
        // Read from UserSettings
        let tripDbPasscode = getCurrentPasscode()
        self.currentPasscodeTextField.text = tripDbPasscode
    }
    
    private func getCurrentPasscode() -> String {
        return UserDefaults.standard.string(forKey: UserSettingsViewController.KEY_TRIP_DB_PASSCODE) ?? ""
    }
    
    private func changePasscode(newPasscode: String) throws {
        let oldPasscode = getCurrentPasscode()
        
        // Build DB passcode provider - with new password.
        let passcodeProvider = DemoDbEncryptProvider(temporaryPasscode: newPasscode.data(using: .utf8) ?? Data())
        
        guard let progress = AlertUtils.buildBlockingProgressValueDialog() else {
            return
        }
        progress.style = .loadingIndicator
        progress.title = "Setting Passcode"
        present(progress, animated: false) {
            // Change the DB passcode in the SDK
            SdkManager.shared.changeDbPasscodeAsync(
                dbDomain: .TRIP,
                oldPasscode: oldPasscode.data(using: .utf8) ?? Data(),
                dbEncryptConfigProvider: passcodeProvider,
                completion: { result in
                    switch result {
                    case .success(_):
                        progress.dismiss(animated: false) {
                            AlertUtils.showAlert(viewController: self, title: "New Passcode Set", message: "")
                            // Save passcode - this is just demo so we can save it into preferences
                            UserDefaults.standard.set(newPasscode, forKey: UserSettingsViewController.KEY_TRIP_DB_PASSCODE)

                            // Now remove the temporary passcode from the provider so the passcode is not visible for anyone else
                            passcodeProvider.discardPassword()

                            self.refreshPasscode()
                        }
                    case .failure(let error):
                        progress.dismiss(animated: false) {
                            self.showError(error)
                        }
                    }
                })
        }
    }
}

