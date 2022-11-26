//
//  VersionTests.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation
@testable import Support
import XCTest

final class VersionTests: XCTestCase {

    func testVersions() throws {
        XCTAssertTrue(try Version.isVersionAbove(minimumVersion: "1.0.0", version: "1.1.0"))
        XCTAssertTrue(try Version.isVersionAbove(minimumVersion: "1", version: "2"))
        XCTAssertTrue(try Version.isVersionAbove(minimumVersion: "0.8", version: "0.9"))
        XCTAssertTrue(try Version.isVersionAbove(minimumVersion: "0.9.8", version: "0.9.9"))
        XCTAssertTrue(try Version.isVersionAbove(minimumVersion: "0.98", version: "0.99"))
        XCTAssertTrue(try Version.isVersionAbove(minimumVersion: "0.9", version: "1"))
    }
}
