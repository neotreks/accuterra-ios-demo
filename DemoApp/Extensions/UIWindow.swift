//
//  UIWindow.swift
//  DemoApp
//
//  Created by Martin Zly on 20.03.2023.
//  Copyright © 2023 NeoTreks. All rights reserved.
//

import UIKit

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
