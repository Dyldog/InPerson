//
//  String+ExtensionsTests.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import XCTest

final class String_ExtensionsTests: XCTestCase {

    func testCommaSeparated() {
        let data: [(String, String)] = [
            ("123456789", "1,2,3,4,5,6,7,8,9"),
            ("abdcdefg", "a,b,d,c,d,e,f,g"),
            ("1a2b3c4d", "1,a,2,b,3,c,4,d"),
            ("27Cvct53^@d", "2,7,C,v,c,t,5,3,^,@,d"),
        ]

        data.forEach {
            XCTAssertEqual($0.0.commaSeparated, $0.1)
        }
    }

    func testInsertEveryFunction() {
        let data: [(input: String, separator: Character, stride: Int, result: String)] = [
            ("12345678", " ", 3, "12 345 678"),
            ("123456789", " ", 3, "123 456 789"),
            ("1234567890", " ", 3, "1 234 567 890"),
            ("123456789", ",", 3, "123,456,789"),
            ("123456789", "$", 2, "1$23$45$67$89"),
            ("123456789", "R", 4, "1R2345R6789"),
        ]

        data.forEach {
            XCTAssertEqual($0.input.insert($0.separator, every: $0.stride), $0.result)
        }
    }
}
