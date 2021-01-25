//
//  DemoAccessManager.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 25/08/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import ObjectMapper
import AccuTerraSDK

/**
* Class for managing access to AccuTerra services
*/
class DemoAccessManager : IAccessProvider {
    private var clientId: String
    private var clientSecret: String
    
    public static var shared: DemoAccessManager = {
        DemoAccessManager()
    }()
    
    private init() {
        guard let WS_AUTH_CLIENT_ID = Bundle.main.infoDictionary?["WS_AUTH_CLIENT_ID"] as? String, WS_AUTH_CLIENT_ID.count > 0 else {
            fatalError("WS_AUTH_CLIENT_ID is missing or not configured in Info.plist")
        }
        clientId = WS_AUTH_CLIENT_ID
        
        guard let WS_AUTH_CLIENT_SECRET = Bundle.main.infoDictionary?["WS_AUTH_CLIENT_SECRET"] as? String, WS_AUTH_CLIENT_SECRET.count > 0 else {
            fatalError("WS_AUTH_CLIENT_SECRET is missing or not configured in Info.plist")
        }
        clientSecret = WS_AUTH_CLIENT_SECRET
    }
    
    /* * * * * * * * * * * * */
    /*        PUBLIC         */
    /* * * * * * * * * * * * */
    
    func getToken(
        callback: @escaping (String) -> Void,
        errorHandler: @escaping (Error) -> Void) {
        getAccessToken(callback: { (token) in
            callback(token.accessToken)
        }, errorHandler: errorHandler)
    }
    
    func getAccuterraMapApiKey() -> String? {
        guard let ACCUTERRA_MAP_API_KEY = Bundle.main.infoDictionary?["ACCUTERRA_MAP_API_KEY"] as? String, ACCUTERRA_MAP_API_KEY.count > 0 else {
            fatalError("ACCUTERRA_MAP_API_KEY is missing or not configured in Info.plist")
        }
        return ACCUTERRA_MAP_API_KEY
    }

    private func getAccessToken(
        callback:@escaping (_ result: AccuTerraAccessToken) -> Void,
        errorHandler:@escaping (_ result:Error) -> Void) {

        if let token = AccessTokenRepo.shared.loadAccessToken() {
            if token.isValid() {
                // The token is valid
                callback(token)
                return
            } else {
                // We need to refresh the existing token
                getRefreshedToken(
                    oldToken: token,
                    callback: { (refreshedToken) in
                        AccessTokenRepo.shared.save(access: refreshedToken)
                        callback(refreshedToken)
                }) { (error) in
                    // We try to get new token, because refresh failed
                    self.getNewAccessToken(callback: { (newToken) in
                        AccessTokenRepo.shared.save(access: newToken)
                        callback(newToken)
                    }) { (error) in
                        errorHandler(error)
                    }
                }
            }
        } else {
            // We need to get new token
            getNewAccessToken(callback: { (token) in
                AccessTokenRepo.shared.save(access: token)
                callback(token)
            }) { (error) in
                errorHandler(error)
            }
        }
    }

    func resetToken(
        callback:@escaping (_ result: AccuTerraAccessToken) -> Void,
        errorHandler:@escaping (_ result:Error) -> Void) {
        
        getNewAccessToken(callback: callback, errorHandler: errorHandler)
    }

    /* * * * * * * * * * * * */
    /*        PRIVATE        */
    /* * * * * * * * * * * * */

    private func getNewAccessToken(
        callback:@escaping (_ result: AccuTerraAccessToken) -> Void,
        errorHandler:@escaping (_ result:Error) -> Void) {
        
        AuthApi.shared.getNewAccessToken(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            grantType: "client_credentials",
            userId: DemoIdentityManager.shared.getUserId(),
            callback: { (response) in
                callback(response.toApi())
        }, errorHandler: errorHandler)
    }

    private func getRefreshedToken(
        oldToken: AccuTerraAccessToken,
        callback:@escaping (_ result: AccuTerraAccessToken) -> Void,
        errorHandler:@escaping (_ result:Error) -> Void) {

        AuthApi.shared.refreshAccessToken(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            grantType: "refresh_token",
            refreshToken: oldToken.refreshToken,
            callback: { (response) in
                callback(response.toApi())
        }, errorHandler: errorHandler)
    }
}

fileprivate extension AuthResponse {
    func toApi() -> AccuTerraAccessToken {
        return AccuTerraAccessToken(
            accessToken: self.accessToken,
            tokenType: self.tokenType,
            refreshToken: self.refreshToken,
            expireDate: getExpirationDate(token: self.accessToken),
            scope: self.scope)
    }
    
    func getExpirationDate(token: String) -> Date {
        let parts = token.split(separator: ".")
        
        if
            parts.count > 2,
            let data = decodeUrlSafeBase64(String(parts[1])),
            let decoded: String = String(data: data, encoding: .utf8),
            let dict: [String: Any] = Mapper<AuthResponse>.parseJSONStringIntoDictionary(JSONString: decoded),
            let exp = dict["exp"] as? Int {
            return Date(timeIntervalSince1970: Double(exp))
        } else {
            fatalError("Cannot parse token expiration, invalid JWT token")
        }
    }
    
    private func decodeUrlSafeBase64(_ value: String) -> Data? {
        var stringtoDecode: String = value.replacingOccurrences(of: "-", with: "+")
        stringtoDecode = stringtoDecode.replacingOccurrences(of: "_", with: "/")
        switch (stringtoDecode.utf8.count % 4) {
            case 2:
                stringtoDecode += "=="
            case 3:
                stringtoDecode += "="
            default:
                break
        }
        return Data(base64Encoded: stringtoDecode, options: [.ignoreUnknownCharacters])
    }
}
