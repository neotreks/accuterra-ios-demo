//
// Created by Rudolf Kopřiva on 09/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation

class DemoIdentityManager : IIdentityProvider {
    
    private static let defaultUserId = "test driver uuid"
    
    public static var shared: DemoIdentityManager = {
        DemoIdentityManager()
    }()
    
    private init() {
    }
    
    func getUserId() -> String {
        // Read from UserDefaults

        // We need to use default value also here since
        let userId = UserDefaults.standard.string(forKey: UserSettingsViewController.KEY_USER_SETTINGS)
        return userId ?? DemoIdentityManager.defaultUserId // We need to set default value here since settings cannot be reset to null and returns "" instead
    }
    
    func setUserId(userId: String?) {
        if let userId = userId, !userId.isEmpty {
            UserDefaults.standard.setValue(userId, forKey: UserSettingsViewController.KEY_USER_SETTINGS)
        } else {
            UserDefaults.standard.removeObject(forKey: UserSettingsViewController.KEY_USER_SETTINGS)
        }
    }
}
