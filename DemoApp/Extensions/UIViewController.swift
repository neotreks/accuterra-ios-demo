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
        Log.e("", "\(error)")
    }
    
    func showInfo(_ text: String) {
        let alert = UIAlertController(title: text, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
}
