//
//  Publisher_ExtensionsTests.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Combine
import Foundation

import XCTest

final class Publisher_ExtensionsTests: XCTestCase {

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        cancellables = .init()
    }

    func testSinkIgnoringAll() {
        var calledPromise: Bool = false

        Future<Void, Never> { promise in
            calledPromise = true
            return promise(.success(()))
        }
        .setFailureType(to: Never.self)
        .sinkIgnoringAll(in: &cancellables)

        XCTAssertTrue(calledPromise)
    }
}
