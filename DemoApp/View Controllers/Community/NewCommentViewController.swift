//
//  NewCommentViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 08.01.2021.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import Foundation
import UIKit
import AccuTerraSDK

protocol NewCommentViewControllerDelegate: class {
    func didAddNewComment(commentsCount: Int?)
}

class NewCommentViewController: UIViewController {

    // MARK:- Outlets
    @IBOutlet weak var textView: UITextView!

    // MARK:- Properties
    weak var delegate: NewCommentViewControllerDelegate? = nil
    var tripUuid: String?

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Comment"
        
        setUpNavBar()
    }

    // MARK:- Actions
    @objc private func onSend() {
        guard let tripUuid = self.tripUuid, self.textView.text.count > 0 else {
            return
        }
        
        let request = PostTripCommentRequest.build(tripUuid: tripUuid, commentText: textView.text)
        postComment(commentRequest: request)
    }

    // MARK:- UI

    private func setUpNavBar() {
        // Right button
        let actionButton = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(self.onSend))
        self.navigationItem.rightBarButtonItem = actionButton
    }

    // MARK:- Comments

    /// Post a comment for given [PostTripCommentRequest]
    private func postComment(commentRequest: PostTripCommentRequest) {
        guard let dialog = AlertUtils.buildBlockingProgressValueDialog() else {
            return
        }
        dialog.title = "Updating Trip"
        dialog.style = .loadingIndicator
        
        self.present(dialog, animated: false, completion: nil)
        
        let service = ServiceFactory.getTripService()
        service.postTripComment(commentRequest: commentRequest) { (result) in
            dialog.dismiss(animated: false, completion: nil)
            if (result.isSuccess) {
                self.delegate?.didAddNewComment(commentsCount: result.value?.commentsCount)
                self.navigationController?.popViewController(animated: true)
            } else {
                self.showError(("Cannot add a comment because of: \(result.buildErrorMessage() ?? "unknown")").toError())
            }
        }
    }
}
