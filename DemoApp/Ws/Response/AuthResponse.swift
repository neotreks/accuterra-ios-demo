//
//  AuthResponse.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 25/08/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import ObjectMapper

/// Authorization response
class AuthResponse : Mappable {
    var accessToken: String!
    var tokenType: String!
    var refreshToken: String!
    var expiresIn: Int!
    var scope: String!
    
    required init?(map: Map){
    }
    
    func mapping(map: Map) {
        accessToken <- map["access_token"]
        tokenType <- map["token_type"]
        refreshToken <- map["refresh_token"]
        expiresIn <- map["expires_in"]
        scope <- map["scope"]
    }
}
