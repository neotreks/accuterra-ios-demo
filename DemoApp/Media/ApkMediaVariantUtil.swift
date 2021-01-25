//
// Created by Rudolf Kopřiva on 28.11.2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/// Utility to get media variant URL
final class ApkMediaVariantUtil {

    ///
    /// This utility method maps media variants defined in the **DEMO APP** [ApkMediaVariant]
    /// to **SDK** media variants defined by [SdkMediaCategory] and [SdkMediaVariant].
    ///
    /// Each tenant should implement his own mapping of those variants.
    /// Also, new variants can appear during the time.
    ///
    static func getUrlForVariant(baseUrl: String, mediaCategoryNumber: Int, variant: ApkMediaVariant) throws -> String {

        if mediaCategoryNumber == SdkMediaCategory.TRAIL_MEDIA.number {
            switch variant {
            case .DEFAULT:
                return try SdkMediaCategory.TRAIL_MEDIA.getVariantUrl(baseUrl: baseUrl, variant: SdkMediaVariant.trail)
            case .THUMBNAIL:
                return try SdkMediaCategory.TRAIL_MEDIA.getVariantUrl(baseUrl: baseUrl, variant: SdkMediaVariant.trailThumbnail)
            }
        }

        if mediaCategoryNumber == SdkMediaCategory.TRAIL_MAP.number {
            switch variant {
            case .DEFAULT:
                return try SdkMediaCategory.TRAIL_MAP.getVariantUrl(baseUrl: baseUrl, variant: SdkMediaVariant.trailMap)
            case .THUMBNAIL:
                return try SdkMediaCategory.TRAIL_MAP.getVariantUrl(baseUrl: baseUrl, variant: SdkMediaVariant.trailMapThumbnail)
            }
        }

        throw "Unsupported media variant \(variant) for category number: \(mediaCategoryNumber)".toError()
    }

}