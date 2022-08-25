//
//  BaseViewController.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/25/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

extension UINavigationBar {
    func setColors(barColor: UIColor, titleColor: UIColor) {
        // iOS 14:
        self.barTintColor = barColor
        self.tintColor = titleColor

        // iOS 15:
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = barColor
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        self.standardAppearance = appearance
        self.scrollEdgeAppearance = appearance
    }
}

class BaseViewController: UIViewController {

    // MARK:- Properties
    weak var homeNavItem: UINavigationItem?
    @IBInspectable var navBarBackgroundTintColor: UIColor?

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavBar()
    }

    // MARK:-
    func setNavBar() {
        self.homeNavItem?.leftBarButtonItem = nil
        self.homeNavItem?.setRightBarButtonItems(nil, animated: false)
        self.homeNavItem?.titleView = nil

        if let navBarBackgroundTintColor = navBarBackgroundTintColor {
            self.navigationController?.navigationBar.setColors(barColor: navBarBackgroundTintColor, titleColor: UIColor.white)
            self.navigationController?.navigationBar.overrideUserInterfaceStyle = .dark
        }

        self.navigationController?.navigationBar.barStyle = .black
    }
    
    var taskBar: TaskBar? {
        get {
            if let homePageViewController = self.parent as? HomePageViewController {
                return (homePageViewController.homeDelegate as? HomeViewController)?.taskBar
            } else if let homeViewController = self.navigationController?.viewControllers.first as? HomeViewController {
                return homeViewController.taskBar
            } else {
                return nil
            }
        }
    }
}
