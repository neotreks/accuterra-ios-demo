//
//  UIApplication.swift
//  DemoApp
//
//  Created by Martin Zly on 20.03.2023.
//  Copyright © 2023 NeoTreks. All rights reserved.
//

import UIKit

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return UIWindow.key!.rootViewController?.topMostViewController()
    }
}
