//
//  AccessTokenRepo.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 25/08/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation

/**
* Repository for the AccessToken
*
* Please this is not a secure implementation since this is just a demo APP.
*/
class AccessTokenRepo {
    
    /* * * * * * * * * * * * */
    /*       STATIC          */
    /* * * * * * * * * * * * */

    static let PREF_NAME = "AccuTerraAccess"
    static let KEY_ACCESS_TOKEN = "AccessToken"
    static let KEY_REFRESH_TOKEN = "RefreshToken"
    static let KEY_TOKEN_EXPIRE = "TokenExpire"
    static let KEY_TOKEN_TYPE = "TokenType"
    static let KEY_TOKEN_SCOPE = "TokenScope"
    
    public static var shared: AccessTokenRepo = {
        return AccessTokenRepo()
    }()
    
    /* * * * * * * * * * * * */
    /*        PUBLIC         */
    /* * * * * * * * * * * * */

    func save(access: AccuTerraAccessToken) {
        UserDefaults.standard.set(access.accessToken, forKey: AccessTokenRepo.KEY_ACCESS_TOKEN)
        UserDefaults.standard.set(access.refreshToken, forKey: AccessTokenRepo.KEY_REFRESH_TOKEN)
        UserDefaults.standard.set(access.expireDate, forKey: AccessTokenRepo.KEY_TOKEN_EXPIRE)
        UserDefaults.standard.set(access.tokenType, forKey: AccessTokenRepo.KEY_TOKEN_TYPE)
        UserDefaults.standard.set(access.scope, forKey: AccessTokenRepo.KEY_TOKEN_SCOPE)
    }

    func loadAccessToken() -> AccuTerraAccessToken? {
        
        if
            let accessToken = UserDefaults.standard.value(forKey: AccessTokenRepo.KEY_ACCESS_TOKEN) as? String,
            let tokenType = UserDefaults.standard.value(forKey: AccessTokenRepo.KEY_TOKEN_TYPE) as? String,
            let refreshToken = UserDefaults.standard.value(forKey: AccessTokenRepo.KEY_REFRESH_TOKEN) as? String,
            let expireIn = UserDefaults.standard.value(forKey: AccessTokenRepo.KEY_TOKEN_EXPIRE) as? Date,
            let scope = UserDefaults.standard.value(forKey: AccessTokenRepo.KEY_TOKEN_SCOPE) as? String {
            
            return AccuTerraAccessToken(accessToken: accessToken, tokenType: tokenType, refreshToken: refreshToken, expireDate: expireIn, scope: scope)
        } else {
            return nil
        }
    }
    
    func reset() {
        UserDefaults.standard.removeObject(forKey: AccessTokenRepo.KEY_ACCESS_TOKEN)
        UserDefaults.standard.removeObject(forKey: AccessTokenRepo.KEY_REFRESH_TOKEN)
        UserDefaults.standard.removeObject(forKey: AccessTokenRepo.KEY_TOKEN_EXPIRE)
        UserDefaults.standard.removeObject(forKey: AccessTokenRepo.KEY_TOKEN_TYPE)
        UserDefaults.standard.removeObject(forKey: AccessTokenRepo.KEY_TOKEN_SCOPE)
    }
    
}
