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
 * Class for managing access to AccuTerra services using credentials
 */
class DemoCredentialsAccessManager : ICredentialsAccessProvider {
    private(set) var clientCredentials: ClientCredentials
    
    public static let shared = DemoCredentialsAccessManager()
    
    private init() {
        guard let WS_AUTH_CLIENT_ID = Bundle.main.infoDictionary?["WS_AUTH_CLIENT_ID"] as? String, WS_AUTH_CLIENT_ID.count > 0 else {
            fatalError("WS_AUTH_CLIENT_ID is missing or not configured in Info.plist")
        }
        
        guard let WS_AUTH_CLIENT_SECRET = Bundle.main.infoDictionary?["WS_AUTH_CLIENT_SECRET"] as? String, WS_AUTH_CLIENT_SECRET.count > 0 else {
            fatalError("WS_AUTH_CLIENT_SECRET is missing or not configured in Info.plist")
        }
        
        clientCredentials = ClientCredentials(clientId: WS_AUTH_CLIENT_ID, clientSecret: WS_AUTH_CLIENT_SECRET)
    }
    
    func resetToken(callback: @escaping () -> Void, errorHandler: @escaping (Error) -> Void) {
        SdkManager.shared.resetAccessToken(callback: callback, errorHandler: errorHandler)
    }
}

/**
 * Class for managing access to AccuTerra services by providing the token
 */
class DemoTokenAccessManager : ITokenAccessProvider {
    func getAccessToken(completion: (String?) -> Void) {
        fatalError("getAccessToken not implemented")
    }
    
    func refreshAccessToken(completion: (String?) -> Void) {
        fatalError("refreshAccessToken not implemented")
    }
}
