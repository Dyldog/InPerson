//
//  Int+ExtensionsTests.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation
@testable import Support
import XCTest

final class Int_ExtensionsTests: XCTestCase {

    func testMakeIterator() {
        let iterator = 10.makeIterator()

        XCTAssertEqual(Array(iterator), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }

    func testIsLastIndex() {
        let array = Array(repeating: 0, count: 10)
        XCTAssertEqual(8.isLastIndex(of: array), false)
        XCTAssertEqual(9.isLastIndex(of: array), true)
        XCTAssertEqual(10.isLastIndex(of: array), false)

        let array2 = Array(repeating: 0, count: 100)
        XCTAssertEqual(98.isLastIndex(of: array2), false)
        XCTAssertEqual(99.isLastIndex(of: array2), true)
        XCTAssertEqual(100.isLastIndex(of: array2), false)
    }
}
