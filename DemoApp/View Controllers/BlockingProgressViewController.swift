//
//  BlockingProgressViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 21/02/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import UIKit

class BlockingProgressViewController : UIViewController {

    // MARK:- Enums
    enum Style {
        case progressBar
        case loadingIndicator
    }

    // MARK:- IBOutlets
    @IBOutlet private weak var dialogView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!

    // MARK:- Properties
    var style = Style.progressBar
    
    var progress: Float {
        get {
            return self.progressView.progress
        }
        set {
            self.progressView.progress = newValue
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK:- Lifecycle
    override func viewDidLoad() {
        self.dialogView.layer.cornerRadius = 5.0
        super.viewDidLoad()
        self.titleLabel.text = self.title
        switch self.style {
        case .loadingIndicator:
            self.loadingIndicator.isHidden = false
            self.progressView.isHidden = true
        case .progressBar:
            self.loadingIndicator.isHidden = true
            self.progressView.isHidden = false
        }
    }
}
