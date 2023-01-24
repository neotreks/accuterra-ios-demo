//
//  PhotoViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 08/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import UIKit

class PhotoViewController : UIViewController {

    // MARK:- Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK:- Properties
    var mediaLoader: MediaLoader?

    // MARK:- Lifecycle
    override func viewDidLoad() {
        guard let mediaLoader = self.mediaLoader else {
            return
        }
        
        activityIndicator.startAnimating()
        mediaLoader.load { [weak self] result in
            if case let .success(value) = result {
                self?.activityIndicator.stopAnimating()
                self?.imageView.image = value.1
            }
        }
    }
}
