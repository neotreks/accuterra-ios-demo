//
//  AlertUtils.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 27/05/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit

class AlertUtils {
    static func showAlert(viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: false, completion: nil)
    }
    
    static func showPrompt(viewController: UIViewController, title: String, message: String, confirmHandler: @escaping () -> Void, cancelHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            confirmHandler()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action) in
            cancelHandler?()
        }))
        viewController.present(alert, animated: false, completion: nil)
    }
    
    static func buildBlockingProgressValueDialog() -> BlockingProgressViewController? {
        if let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "BlockingProgressVC") as? BlockingProgressViewController {
            vc.modalPresentationStyle = .overCurrentContext
            return vc
        }
        return nil
    }
}
