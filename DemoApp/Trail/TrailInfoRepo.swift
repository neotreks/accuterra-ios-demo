//
//  TrailInfoRepo.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 27.11.2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

class TrailInfoRepo {
    static func loadTrailComments(trailId: Int64, completion: @escaping (Result<GetTrailCommentsResult, Error>) -> Void) throws {
        let service = ServiceFactory.getTrailService()
        
        let criteria = try GetTrailCommentsCriteriaBuilder.build(trailId: trailId)
        
        return service.getTrailComments(criteria: criteria, completion: completion)
    }
    
    static func loadTrailUserData(trailId: Int64) throws -> TrailUserData {
        let service = ServiceFactory.getTrailService()
        return try service.getTrailUserData(trailId: trailId)
    }
}
