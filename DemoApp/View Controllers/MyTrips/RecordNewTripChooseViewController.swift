//
//  RecordNewTripChooseViewController.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 5/28/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

class RecordNewTripChooseViewController: BaseViewController {

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Record New Trip"
    }

    // MARK:- IBActions
    @IBAction func buttonChooseRouteTapped(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
        taskBar?.select(task: .discover)
    }
    
    @IBAction func buttonFreeRoamTapped(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "RecordNewTripVC") as? RecordNewTripViewController {
            vc.title = "Record New Free Roam Trip"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func buttonTrailCollectionTapped(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "TrailCollectionVC") as? TrailCollectionViewController {
            vc.title = "Trail Collection Mode"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
