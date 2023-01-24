//
//  SettingsViewController.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/18/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK

class SettingsViewController: BaseViewController {

    // MARK:- Properties
    private let TAG = "SettingsViewController"
    static let trailCollectionModeKey = "trailCollectionModeKey"
    
    // MARK:- IBOutlets
    @IBOutlet weak var textFieldUserId: UITextField!
    @IBOutlet weak var trailCollectionModeSwitch: UISwitch!
    
    // MARK:- Lifecycle
    override func viewDidLoad() {
        self.title = "Settings"
        self.textFieldUserId.text = DemoIdentityManager.shared.getUserId()
        let collectionMode = UserDefaults.standard.object(forKey: Self.trailCollectionModeKey)
        trailCollectionModeSwitch.isOn = (collectionMode as? Bool) ?? false
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.textFieldUserId.autocapitalizationType = UITextAutocapitalizationType.sentences
    }
    
    @IBAction func trailCollectionModeChanged(_ sender: Any) {
        let isOn = (sender as? UISwitch)?.isOn ?? false
        UserDefaults.standard.set(isOn, forKey: Self.trailCollectionModeKey)
    }
}

// MARK:- UITextFieldDelegate extension
extension SettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        DemoIdentityManager.shared.setUserId(userId: textFieldUserId.text)
        DemoCredentialsAccessManager.shared.resetToken { result in
            switch result {
            case .success(_):
                Log.d(self.TAG, "Access token reset finished.")
            case .failure(let error):
                self.showError(error)
            }
        }

        return true
    }
}
