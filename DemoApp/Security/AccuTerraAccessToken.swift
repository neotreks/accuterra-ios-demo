//
//  AccuTerraAccessToken.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 25/08/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

/**
 * Access token for AccuTerra Services
 */
struct AccuTerraAccessToken {

    var accessToken: String

    var tokenType: String

    var refreshToken: String

    var expireDate: Date

    var scope: String
    
    /**
     * Return true if the token does not expire in next 60 seconds.
     */
    func isValid() -> Bool {
        return expireDate.timeIntervalSince(Date()) > 60
    }
}
