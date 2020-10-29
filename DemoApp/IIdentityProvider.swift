//
// Created by Rudolf Kopřiva on 09/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation

/// Provides user identity info
protocol IIdentityProvider {

    /// Provides user's unique identifier.
    /// This identifier is used across the SDK e.g. in WS calls, etc.
    func getUserId() -> String
}