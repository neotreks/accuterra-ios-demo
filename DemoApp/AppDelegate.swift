//
//  AppDelegate.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 13/12/2019.
//  Copyright © 2019 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Kingfisher
import Combine

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var cancellableRefs = [AnyCancellable]()
    private let thermalStateMonitor = ThermalStateMonitor.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set log level to debug
        Log.level = .debug
        listenForTrailUploadNotification()
        listenForThermalStateNotification()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    private func listenForTrailUploadNotification() {
        NotificationCenter.default
            .publisher(for: TripRecordingStatusChangeNotification.name)
            .receive(on: DispatchQueue.main)
            .sink() { [weak self] notification in
                self?.onTripStatusChanged(notification: notification)
            }
            .store(in: &cancellableRefs)
    }
    
    private func onTripStatusChanged(notification: Notification) {
        if let userInfo = notification.userInfo as? [String: Any] {
            if let statusChange = userInfo[TripRecordingStatusChangeNotification.name.rawValue] as? TripRecordingStatusChange {
                if statusChange.status == .UPLOADED {
                    sendNotification(trailName: statusChange.name ?? "")
                }
            }
        }
    }
    
    private func sendNotification(trailName: String) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.body = "Uploaded trail: \(trailName)"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2,
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: "TrailUploadNotification",
                                            content: notificationContent,
                                            trigger: trigger)
        
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.add(request) { (error) in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
        userNotificationCenter.delegate = self
    }
    
    private func listenForThermalStateNotification() {
        
        thermalStateMonitor.state
            .receive(on: DispatchQueue.main).sink { [weak self] value in
                self?.onThermalStateChanged(state: value)
            }
            .store(in: &cancellableRefs)
    }
    
    private func onThermalStateChanged(state: ProcessInfo.ThermalState) {
        
        if state == .critical {
            let alertController = UIAlertController(title: "Warning", message: state.description, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            
            UIApplication.shared.topMostViewController()?.present(alertController, animated: true, completion: nil)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}
