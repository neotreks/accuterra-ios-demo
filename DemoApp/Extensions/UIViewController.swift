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
    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
        Log.e("", "\(error)")
    }
}
