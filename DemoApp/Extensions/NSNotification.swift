//
//  NSNotification.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 29.02.2024.
//  Copyright © 2024 NeoTreks. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let userChanged = NSNotification.Name("UserChanged")
}

extension Notification.Name {
    static let TrailsUpdated = Notification.Name.init(rawValue: "TrailsUpdated")
}
