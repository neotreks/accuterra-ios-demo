import UIKit
import AccuTerraSDK

class HomeViewController: UIViewController {

    // MARK:- Outlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var taskBar: TaskBar!


    private var timer: Timer!

    // MARK:- Properties
    var homePageViewController: HomePageViewController? {
        didSet {
            homePageViewController?.homeDelegate = self
        }
    }

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = String.appTitle
        taskBar.delegate = self

        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.isTranslucent = false

        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { timer in

            guard SdkManager.shared.isInitialized else {
                return
            }

            if (try? ServiceFactory.getTripRecorder())?.hasActiveTripRecording() == true {
                UIApplication.shared.isIdleTimerDisabled = true
                return
            }


            let queuedRecordings = try? ServiceFactory.getTripRecordingService().findTripRecordings(criteria: TripRecordingSearchCriteria(name: nil, status: .QUEUED, orderBy: TripOrderBy.init(property: .NAME, order: .ascending), limit: 1))
            if (queuedRecordings?.count ?? 0) > 0 {
                UIApplication.shared.isIdleTimerDisabled = true
                return
            }

            UIApplication.shared.isIdleTimerDisabled = false
        })
    }

    // MARK:-
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let homePageViewController = segue.destination as? HomePageViewController {
            self.homePageViewController = homePageViewController
            self.homePageViewController?.homeNavItem = navigationItem
        }
    }
    /**
     Fired when the user taps on the pageControl to change its current page.
     */
    func didChangePageControlValue() {
    }
}

// MARK:- HomePageViewControllerDelegate extension
extension HomeViewController: HomePageViewControllerDelegate {
    func homePageViewController(homePageViewController: HomeViewController, didUpdatePageCount count: Int) {
        //
    }
    
    func homePageViewController(homePageViewController: HomeViewController, didUpdatePageIndex index: Int) {
        //
    }
    
    func updateSelection(task: TaskTypes) {
        taskBar.updateSelection(task: task)
    }
}

// MARK:- TaskbarDelegate extension
extension HomeViewController: TaskbarDelegate {
    func taskSelected(task: TaskTypes) {
        homePageViewController?.scrollToViewController(index: UIUtils.getIndexFromTask(task: task))
    }
}
