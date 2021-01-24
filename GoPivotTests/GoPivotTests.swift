//
//  GoPivotTests.swift
//  GoPivotTests
//
//  Created by Ryan Schumacher on 1/24/21.
//  Copyright © 2021 Schu Studios, LLC. All rights reserved.
//

import XCTest
@testable import GoPivot

class GoPivotTests: XCTestCase {
    let v100 = "1.0.0"
    let v10 = "1.0"
    let v102 = "1.0.2"
    let v200 = "2.0.0"

    let v1010 = "1.0.10"
    let v109 = "1.0.9"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVersionCompareSame() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(v100.versionCompare(v100), .orderedSame)
        XCTAssertEqual(v10.versionCompare(v10), .orderedSame)
        XCTAssertEqual(v100.versionCompare(v10), .orderedSame)
        XCTAssertEqual(v200.versionCompare(v200), .orderedSame)
    }

    func testVersionCompareDifferent() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(v100.versionCompare(v102), .orderedAscending)
        XCTAssertEqual(v10.versionCompare(v102), .orderedAscending)
        XCTAssertEqual(v102.versionCompare(v10), .orderedDescending)
        XCTAssertEqual(v102.versionCompare(v100), .orderedDescending)
        XCTAssertEqual(v200.versionCompare(v100), .orderedDescending)

        XCTAssertEqual(v1010.versionCompare(v109), .orderedDescending)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
