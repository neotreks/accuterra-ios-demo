//
//  HomeViewController.swift
//  DemoApp
//
//  Created by Brian Elliott on 2/20/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Mapbox

// MARK:- Protocols
protocol HomePageViewControllerDelegate: AnyObject {
    /// The number of pages is updated.
    ///
    /// - Parameters:
    ///   - homePageViewController: the TutorialPageViewController instance
    ///   - count: the total number of pages.
    func homePageViewController(homePageViewController: HomeViewController,
                                didUpdatePageCount count: Int)

    /// The current index is updated.
    ///
    /// - Parameters:
    ///   - homePageViewController: the TutorialPageViewController instance
    ///   - index: the index of the currently visible page.
    func homePageViewController(homePageViewController: HomeViewController,
                                didUpdatePageIndex index: Int)
    
    func updateSelection(task: TaskTypes)
}

// MARK:- Class
class HomePageViewController: UIPageViewController {

    // MARK:- Properties
    weak var homeDelegate: HomePageViewControllerDelegate?
    weak var homeNavItem: UINavigationItem?
    var checkingForUpdatesDialog: BlockingProgressViewController?
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [
            self.newViewController("Community"),
            self.newViewController("My Trips"),
            self.newViewController("Discover"),
            self.newViewController("Profile")
            ]
    }()

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        handleLaunchMode()
    }

    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    private func load() {
        // By default Mapbox is limitting max tiles count to 6000. If you are using AccuTerra SDK to download Mapbox tiles
        // you should get approval from Mapbox to increase this value
        MGLOfflineStorage.shared.setMaximumAllowedMapboxTiles(UInt64(Int.max))
        
        // Checking if DB is initialized is here just for the DEMO purpose.
        // You should not check this in real APK but call the `SdkManager.configureSdkAsync`
        // and monitor the progress and result. The TRAIL DB will be downloaded automatically
        // during the SDK initialization.
        if !SdkManager.shared.isTrailDbInitialized {
            // Init the SDK. Since DB was not downloaded yet, it will be downloaded
            // during SDK initialization.
            self.goToDownload()
        } else {
            // Init the SDK. Since DB was downloaded already there will be no download now.

            if NetworkUtils.shared.isOnline() {
                if let dialog = AlertUtils.buildBlockingProgressValueDialog() {
                    dialog.title = "Checking for updates"
                    dialog.style = .loadingIndicator
                    self.present(dialog, animated: false, completion: nil)
                    self.checkingForUpdatesDialog = dialog
                }
            }

            self.initSdk()
        }
        
        self.isPagingEnabled = false
    }
    
    private func initSdk() {
        SdkManager.shared.initSdkAsync(
            config: demoAppSdkConfig,
            accessProvider: DemoCredentialsAccessManager.shared,
            identityProvider: DemoIdentityManager.shared,
            delegate: self,
            dbEncryptConfigProvider: DemoDbEncryptProvider())
    }

    // MARK:-
    private func goToDownload() {
        let taskBar = (homeDelegate as? HomeViewController)?.taskBar
        if let downloadViewController = self.newViewController("Download") as? DownloadViewController {
            downloadViewController.delegate = self
            taskBar?.isUserInteractionEnabled = false
            self.scrollToViewController(viewController: downloadViewController)
        }
    }
    
    func goToTrailsDiscovery() {
        let initialViewController = orderedViewControllers[UIUtils.getIndexFromTask(task: .discover)]
        scrollToViewController(viewController: initialViewController)
    }

    func goToTrailCollectionScreen() {
        let initialViewController = orderedViewControllers[UIUtils.getIndexFromTask(task: .mytrips)]
        scrollToViewController(viewController: initialViewController)
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "TrailCollectionVC") as? TrailCollectionViewController {
            vc.title = "Trail Collection Mode"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func handleLaunchMode() {
        if UserDefaults.standard.object(forKey: SettingsViewController.trailCollectionModeKey) == nil {
            AlertUtils.showPrompt(viewController: self, title: "", message: "Would you like to launch the app in trail collection mode? You can change the mode at any time under Profile -> Settings.", confirmHandler: {
                self.load()
                self.homeDelegate?.updateSelection(task: .mytrips)
                UserDefaults.standard.set(true, forKey: SettingsViewController.trailCollectionModeKey)
            }, cancelHandler: {
                self.load()
                self.homeDelegate?.updateSelection(task: .discover)
                UserDefaults.standard.set(false, forKey: SettingsViewController.trailCollectionModeKey)
            })
        }
        else {
            self.load()
            let launchInCollectionMode = (UserDefaults.standard.object(forKey: SettingsViewController.trailCollectionModeKey) as? Bool) ?? false
            if launchInCollectionMode {
                homeDelegate?.updateSelection(task: .mytrips)
            }
            else {
                homeDelegate?.updateSelection(task: .discover)
            }
        }
    }
    
    /// Scrolls to the view controller at the given index. Automatically calculates the direction.
    ///
    /// - Parameter newIndex: the new index to scroll to
    func scrollToViewController(index newIndex: Int) {
        if let firstViewController = viewControllers?.first,
            let currentIndex = orderedViewControllers.firstIndex(of: firstViewController) {
            let direction: UIPageViewController.NavigationDirection = newIndex >= currentIndex ? .forward : .reverse
                let nextViewController = orderedViewControllers[newIndex]
                scrollToViewController(viewController: nextViewController, direction: direction)
        }
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        (homeDelegate as? HomeViewController)?.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    func newViewController(_ name: String) -> UIViewController {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: name) as? BaseViewController {
            vc.homeNavItem = self.homeNavItem
            return vc
        }
        return UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewController(withIdentifier: name)
    }

    /// Scrolls to the given 'viewController' page.
    ///
    /// - Parameters:
    ///   - viewController: the view controller to show.
    ///   - direction: direction
    private func scrollToViewController(viewController: UIViewController,
                                        direction: UIPageViewController.NavigationDirection = .forward) {
        setViewControllers([viewController],
            direction: direction,
            animated: true,
            completion: { (finished) -> Void in
                // Setting the view controller programmatically does not fire
                // any delegate methods, so we have to manually notify the
                // 'tutorialDelegate' of the new index.
                self.notifyTutorialDelegateOfNewIndex()
        })
    }
    
    /// Notifies '_tutorialDelegate' that the current page index was updated.
    private func notifyTutorialDelegateOfNewIndex() {
    }
    
    private func displaySdkInitError(_ error: Error?) {
        let alert = UIAlertController(title: "Error", message: "AccuTerra SDK initialization has failed because of:|\n\(String(describing: error))|\nDo not use the SDK in case of initialization failure!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
}

// MARK:- UIPageViewControllerDataSource extension
extension HomePageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
                return nil
            }
            
            let previousIndex = viewControllerIndex - 1
            
            // User is on the first view controller and swiped left to loop to
            // the last view controller.
            guard previousIndex >= 0 else {
                return orderedViewControllers.last
            }
            
            guard orderedViewControllers.count > previousIndex else {
                return nil
            }
            
            return orderedViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
                return nil
            }
            
            let nextIndex = viewControllerIndex + 1
            let orderedViewControllersCount = orderedViewControllers.count
            
            // User is on the last view controller and swiped right to loop to
            // the first view controller.
            guard orderedViewControllersCount != nextIndex else {
                return orderedViewControllers.first
            }
            
            guard orderedViewControllersCount > nextIndex else {
                return nil
            }
            
            return orderedViewControllers[nextIndex]
    }
    
}

// MARK:- UIPageViewControllerDelegate extension
extension HomePageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool) {
        notifyTutorialDelegateOfNewIndex()
    }
}

// MARK:- SdkInitDelegate and DownloadViewControllerDelegate extensions
extension HomePageViewController : SdkInitDelegate, DownloadViewControllerDelegate {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool) {
        self.present(viewControllerToPresent, animated: flag, completion: nil)
    }
    
    func onProgressChanged(progress: Int) {
        // no action needed here
    }
    
    func onStateChanged(state: SdkInitState, detail: SdkInitStateDetail?) {
        executeBlockOnMainThread {
            let taskBar = (self.homeDelegate as? HomeViewController)?.taskBar
            switch state {
            case .COMPLETED:
                /// Start updating locations in case recording is active
                let locationService = LocationService.shared
                if locationService.requestingLocationRecording && !locationService.requestingLocationUpdates {
                    locationService.requestingLocationUpdates = true
                    locationService.allowBackgroundLocationUpdates = true
                }
                
                taskBar?.isUserInteractionEnabled = true
            
                if UserDefaults.standard.bool(forKey: SettingsViewController.trailCollectionModeKey) {
                    self.goToTrailCollectionScreen()
                }
                else {
                    self.goToTrailsDiscovery()
                }
                
                let service = ServiceFactory.getUploadService()
                service.resumeUploadQueue()
                self.checkingForUpdatesDialog?.dismiss(animated: false, completion: nil)
                self.checkingForUpdatesDialog = nil
                
            case .FAILED(let error):
                taskBar?.isUserInteractionEnabled = true
                self.displaySdkInitError(error)
                self.checkingForUpdatesDialog?.dismiss(animated: false, completion: nil)
                self.checkingForUpdatesDialog = nil
            case .IN_PROGRESS:
                taskBar?.isUserInteractionEnabled = false
            default:
                // no action needed here
                break
            }
        }
    }
}
