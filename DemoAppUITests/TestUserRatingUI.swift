//
//  TestUserRatingUI.swift
//  TestUserRatingUI
//
//  Created by Brian Elliott on 2/11/20.
//  Copyright © 2020 BaseMap. All rights reserved.
//

import XCTest

class TestUserRatingUI: BaseUITest {

    func testTrailUserRating() {
        // We should be on Discovery screem and there should be a table with list of trails
        let firstCellInDiscovery = app.scrollViews.otherElements.tables.cells.firstMatch
        XCTAssertTrue(firstCellInDiscovery.waitForExistence(timeout: 5))

        // Tap on disclosure button of the first trail
        firstCellInDiscovery.buttons["Forward"].tap()

        // Tap on the last star icon in user rating
        let lastStarElement = app.images.containing(.image, identifier: "star").element(boundBy: 4)
        XCTAssertTrue(lastStarElement.waitForExistence(timeout: 5))
        lastStarElement.tap()

        // There should be now 4 and half stars rating
        XCTAssert(app.images.containing(.image, identifier: "star").count == 0)
        XCTAssert(app.images.containing(.image, identifier: "star.fill").count == 4)
        XCTAssert(app.images.containing(.image, identifier: "star.lefthalf.fill").count == 1)
    }
}
