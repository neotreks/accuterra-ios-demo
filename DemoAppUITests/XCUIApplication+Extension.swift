//
//  XCUIApplication+Extension.swift
//  DemoAppUITests
//
//  Created by Rudolf Kopřiva on 27.01.2023.
//  Copyright © 2023 NeoTreks. All rights reserved.
//

import Foundation
import XCTest

extension XCUIApplication {


    /// Tap on button in alert when we know title
    /// - Parameters:
    ///   - title: title of the alert
    ///   - button: button text to tap
    func handleAlert(title: String, withTappingOnButton button: String) {
        self.alerts[title].scrollViews.otherElements.buttons[button].tap()
    }

    /// Tap on button in alert when we know title
    /// - Parameters:
    ///   - title: title of the alert
    ///   - buttonIndex: button index text to tap
    func handleAlert(title: String, withTappingOnButtonIndex buttonIndex: Int) {
        self.alerts[title].buttons.element(boundBy: buttonIndex).tap()
    }


    /// Tap on button in alert when we know message
    /// - Parameters:
    ///   - message: message of the alert
    ///   - button: button text to tap
    func handleAlert(message: String, withTappingOnButton button: String) {
        let alert = self.alerts.containing(.staticText, identifier: message)
        alert.scrollViews.otherElements.buttons[button].tap()
    }

    /// Tap on button in alert when we know message
    /// - Parameters:
    ///   - message: message of the alert
    ///   - buttonIndex: button index to tap
    func handleAlert(message: String, withTappingOnButtonIndex buttonIndex: Int) {
        let alert = self.alerts.containing(.staticText, identifier: message)
        alert.buttons.element(boundBy: buttonIndex).tap()
    }


    /// Checks whether alert  with message exists
    /// - Parameter message: message of the alert we are checking
    /// - Returns: true if alert exists
    func alertExists(message: String) -> Bool {
        self.alerts.containing(.staticText, identifier: message).element.exists
    }


    /// Checkes whether alert with title exists
    /// - Parameter title: title of the alert we are checking
    /// - Returns: true if alert exists
    func alertExists(title: String) -> Bool {
        self.alerts[title].exists
    }


    @discardableResult
    /// Waits until alert appears
    /// - Parameters:
    ///   - title: title of the alert we are waiting for
    ///   - timeout: timeout interval
    ///   - required: when true and alert does not appear the test will fail
    /// - Returns: true if the alert appears before timeout
    func waitForAlert(title: String, timeout: TimeInterval, required: Bool) -> Bool {
        let found = self.alerts[title].waitForExistence(timeout: timeout)
        if !found && required {
            XCTFail("Timeout out while waiting for alert with title \(title)")
        }
        return found
    }


    @discardableResult
    /// Waits until alert appears
    /// - Parameters:
    ///   - message: message of the alert we are waiting for
    ///   - timeout: timeout interval
    ///   - required: when true and alert does not appear the test will fail
    /// - Returns: true if the alert appears before timeout
    func waitForAlert(message: String, timeout: TimeInterval, required: Bool) -> Bool {
        let found = self.alerts.containing(.staticText, identifier: message).element.waitForExistence(timeout: timeout)
        if !found && required {
            XCTFail("Timeout out while waiting for alert with message \(message)")
        }
        return found
    }
}
