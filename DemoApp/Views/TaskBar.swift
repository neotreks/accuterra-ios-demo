//
//  MenuBar.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/18/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit

protocol TaskbarDelegate: AnyObject {
    func taskSelected(task: TaskTypes)
}

enum TaskTypes: String {
    case community = "COMMUNITY"
//    case activities = "ACTIVITIES"
    case mytrips = "MY TRIPS"
    case discover = "DISCOVER"
    case profile = "PROFILE"
}

class TaskBar: UIView {
        
    static var tasks: [Int: TaskTypes] {
        return [
            0: .community,
//            1: .activities,
            1: .mytrips,
            2: .discover,
            3: .profile
        ]
    }
    
    var delegate:TaskbarDelegate?

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.white
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    let cellId = "taskCellId"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
       super.awakeFromNib()
        
        collectionView.register(TaskbarCell.self, forCellWithReuseIdentifier: cellId)

        addSubview(collectionView)
        addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        addConstraintsWithFormat("V:|[v0]|", views: collectionView)
        
        // Initially select tab Discover
        let selectedIndexPath = IndexPath(item: UIUtils.getIndexFromTask(task: .discover), section: 0)
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .bottom)
    }
}

extension TaskBar: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return TaskBar.tasks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! TaskbarCell
        cell.title?.text = TaskBar.tasks[indexPath.row]?.rawValue
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width / CGFloat(TaskBar.tasks.count), height: frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.taskSelected(task: getTask(taskIndex: indexPath.row))
    }
    
    func getTask (taskIndex: Int) -> TaskTypes {
        return TaskBar.tasks[taskIndex] ?? .discover
    }
    
    func select(task: TaskTypes) {
        if let index = TaskBar.tasks.first(where: { (key, value) -> Bool in
            return value == task
        }) {
            self.collectionView.selectItem(at: IndexPath(row: index.key, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            delegate?.taskSelected(task: task)
        }
    }
}
