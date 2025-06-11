//
//  UIViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 23/10/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit
import AccuTerraSDK

extension UIViewController {
    private static let TAG = LogTag(subsystem: "ATDemoApp", category: "UIViewControllerExtension")

    func tryOrShowError<T>(_ block: () throws -> T) -> T? {
        do {
            return try block()
        } catch {
            showError(error)
            return nil
        }
    }
    
    func tryOrShowError(_ block: () throws -> Void) {
        do {
            try block()
        } catch {
            showError(error)
        }
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
        Log.e(UIViewController.TAG, "\(error)")
    }
    
    func showInfo(_ text: String, _ handler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: text, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            action in
            handler?()
        }))
        self.present(alert, animated: false, completion: nil)
    }
    
    func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}
