//
//  BaseViewController.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/25/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

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
            self.navigationController?.navigationBar.barTintColor = navBarBackgroundTintColor
            self.navigationController?.navigationBar.tintColor = UIColor.white
            self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
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
