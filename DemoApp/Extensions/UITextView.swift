//
//  UITextView.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 28.03.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    func extendToolbar() {
        let done : UIToolbar = UIToolbar(
            frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 50))
        done.barStyle = UIBarStyle.default
        let flexibelSpaceItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        let hideKeyboardItem = UIBarButtonItem(
            title: "Done", style: UIBarButtonItem.Style.done, target: self,
            action: #selector(resignFirstResponder))
        done.items = [flexibelSpaceItem, hideKeyboardItem]
        done.sizeToFit()
        inputAccessoryView = done
    }
    
    func removeToolbarExtension() {
        inputAccessoryView = nil
    }
}
