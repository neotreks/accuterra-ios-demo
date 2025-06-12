//
//  BaseUITest.swift
//  DemoAppUITests
//
//  Created by Rudolf Kopřiva on 27.01.2023.
//  Copyright © 2023 NeoTreks. All rights reserved.
//

import Foundation
import XCTest

internal class BaseUITest: XCTestCase {

    var app: XCUIApplication!
    var springBoard: XCUIApplication!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]
        app.launch()

        springBoard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        handleInitialLaunch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    private func handleInitialLaunch() {
        let initialLaunchAlertTitle = "Would you like to launch the app in trail collection mode? You can change the mode at any time under Profile -> Settings."


        let isFirstLaunch = app.alertExists(message: initialLaunchAlertTitle)
        if isFirstLaunch {
            // Tap on No button in the alert
            app.handleAlert(message: initialLaunchAlertTitle, withTappingOnButton: "No")

            app.waitForAlert(title: "Download", timeout: 2, required: true)
            if app.alertExists(title: "Download") {
                // Tap on Ok button in the Download db alert
                app.handleAlert(title: "Download", withTappingOnButton: "Ok")
            }

            // After the download a permission dialog should appear. It is a system dialog, so we use SpringBoard application
            // Wait until the dialog appears on tap on Allow While Using App

            let locationPermissionMessage = "The AccuTerra Trails needs your location to display it on the map."
            springBoard.waitForAlert(message: locationPermissionMessage, timeout: 60, required: true)
            springBoard.handleAlert(message: locationPermissionMessage, withTappingOnButtonIndex: 1)
        }

        // The application can update data on launch. Wait while the update dialog is on screen.
        while app.staticTexts["Checking for updates"].exists {
            Thread.sleep(forTimeInterval: 1)
        }

        // Download overlay dialog might appear, tap on Yes to download the overlay
        let downloadOverlayMessage = "Would you like to download Overlay map cache (~33.8 MB)?"

        if app.alertExists(message: downloadOverlayMessage) {
            app.handleAlert(message: downloadOverlayMessage, withTappingOnButton: "Yes")
        }
    }
}

