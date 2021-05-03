//
//  DemoDbEncryptProvider.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 06.04.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// The implementation of the [IDBEncryptConfigProvider]
class DemoDbEncryptProvider: IDBEncryptConfigProvider {

    private var temporaryPasscode: Data?

    /// The default constructor must be provided. This is requested by the SDK.
    init() {
        self.temporaryPasscode = nil
    }

    /// This constructor is intended for `change password` functionality.
    /// Do not forget to call the [discardPassword] method after the password is changed!
    init(temporaryPasscode: Data) {
        self.temporaryPasscode = temporaryPasscode
    }

    func getTripRecordingPasscode() -> Data {
        // Check if the temporary password is present. Provide it if needed.
        let passcode = temporaryPasscode
        if let passcode = passcode {
            return passcode
        }
        
        // Read from user default.
        if let stringPassCode = UserDefaults.standard.string(forKey: UserSettingsViewController.KEY_TRIP_DB_PASSCODE),
           let passCodeData = stringPassCode.data(using: .utf8) {
            return passCodeData
        } else {
            return Data()
        }
    }

    /// Removes the temporary password from the memory.
    func discardPassword() {
        self.temporaryPasscode = nil
    }
}
