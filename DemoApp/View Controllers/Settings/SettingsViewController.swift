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

    // MARK:- IBOutlets
    @IBOutlet weak var textFieldUserId: UITextField!

    // MARK:- Lifecycle
    override func viewDidLoad() {
        self.title = "Settings"
        self.textFieldUserId.text = DemoIdentityManager.shared.getUserId()
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.textFieldUserId.autocapitalizationType = UITextAutocapitalizationType.sentences
    }
}

// MARK:- UITextFieldDelegate extension
extension SettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        DemoIdentityManager.shared.setUserId(userId: textFieldUserId.text)
        DemoAccessManager.shared.resetToken { (token) in
            Log.d(self.TAG, "Access token reset finished.")
        } errorHandler: { (error) in
            self.showError(error)
        }

        return true
    }
}
