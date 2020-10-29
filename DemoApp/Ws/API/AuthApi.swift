//
//  AuthApi.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 25/08/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

// API for accessing WS Authorization endpoint
class AuthApi {

    private var apiUrl: String
    private static let timeout: TimeInterval = 30 // seconds

    private(set) var sessionManager: Session = {
        var sessionManager = Alamofire.Session()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AuthApi.timeout
        sessionManager = Alamofire.Session(configuration: configuration)
        return sessionManager
    }()

    public static var shared: AuthApi = {
        return AuthApi()
    }()
    
    private init() {
        guard let WS_AUTH_URL = Bundle.main.infoDictionary?["WS_AUTH_URL"] as? String else {
            fatalError("WS_AUTH_URL is missing in Info.plist")
        }
        apiUrl = WS_AUTH_URL + "auth/"
    }
    
    func getNewAccessToken(
        clientId: String,
        clientSecret: String,
        grantType: String,
        userId: String,
        callback:@escaping (_ result:AuthResponse) -> Void,
        errorHandler:@escaping (_ result:Error) -> Void) -> Void {
        
        let params = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": grantType,
            "user_id": userId
        ]
        
        self.sessionManager.request("\(self.apiUrl)token", method: .post, parameters: params, encoding: URLEncoding.default, headers: nil).responseJSON(queue: DispatchQueue.global(), options: .allowFragments) { response in
            switch response.result {
            case .success:
                if let result = Mapper<AuthResponse>().map(JSONObject:response.value) {
                    callback(result)
                }
                else {
                    errorHandler((response.value != nil ? "\(response.value!)" : "Could not map response to AuthResponse").toError(code: response.response!.statusCode))
                }
            case .failure(let error):
                errorHandler(error)
            }
        }
    }
    
    func refreshAccessToken(
        clientId: String,
        clientSecret: String,
        grantType: String,
        refreshToken: String,
        callback:@escaping (_ result:AuthResponse) -> Void,
        errorHandler:@escaping (_ result:Error) -> Void) -> Void {
        
        let params = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": grantType,
            "refresh_token": refreshToken
        ]
        
        self.sessionManager.request("\(self.apiUrl)token", method: .post, parameters: params, encoding: URLEncoding.default, headers: nil).responseJSON(queue: DispatchQueue.global(), options: .allowFragments) { response in
            switch response.result {
            case .success:
                if let result = Mapper<AuthResponse>().map(JSONObject:response.value) {
                    callback(result)
                }
                else {
                    errorHandler((response.value != nil ? "\(response.value!)" : "Could not map response to AuthResponse").toError(code: response.response!.statusCode))
                }
            case .failure(let error):
                errorHandler(error)
            }
        }
    }

}
