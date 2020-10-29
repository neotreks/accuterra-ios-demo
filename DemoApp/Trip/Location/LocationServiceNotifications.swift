//
// Created by Rudolf Kopřiva on 09/10/2020.
// Copyright (c) 2020 NeoTreks. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceNotification {
    static var Name: Notification.Name { get }
}

struct LocationUpdatedNotification : LocationServiceNotification {
    static let Name = Notification.Name(rawValue: "LocationUpdatedNotification")

    let location: CLLocation

    init(location: CLLocation) {
        self.location = location
    }

    var userInfo: [String: Any] {
        [LocationUpdatedNotification.Name.rawValue: self]
    }
}

struct HeadingUpdatedNotification : LocationServiceNotification {
    static let Name = Notification.Name(rawValue: "HeadingUpdatedNotification")

    let heading: CLHeading

    init(heading: CLHeading) {
        self.heading = heading
    }

    var userInfo: [String: Any] {
        [HeadingUpdatedNotification.Name.rawValue: self]
    }
}

extension Notification {

    func getLocationServiceNotification<T>() -> T? where T : LocationServiceNotification {
        if let notification = userInfo?[T.Name.rawValue] as? T {
            return notification
        } else {
            return nil
        }
    }

}