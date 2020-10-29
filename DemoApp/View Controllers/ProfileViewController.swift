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
    
    private let TAG = "ProfileViewController"
    
    @IBOutlet weak var textFieldUserId: UITextField!

    override func viewDidLoad() {
        self.title = "User Profile"
        self.textFieldUserId.text = DemoIdentityManager.shared.getUserId()
        super.viewDidLoad()
    }
}

extension ProfileViewController : UITextFieldDelegate {
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
