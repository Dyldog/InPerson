//
//  Publisher+DidSet.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import Combine

extension Publisher where Failure == Never {
    var didSet: AnyPublisher<Output, Never> {
        self.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
}
