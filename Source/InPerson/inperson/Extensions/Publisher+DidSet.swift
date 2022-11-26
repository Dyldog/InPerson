//
//  Publisher+DidSet.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Combine
import Foundation

extension Publisher where Failure == Never {
    var didSet: AnyPublisher<Output, Never> {
        receive(on: RunLoop.main).eraseToAnyPublisher()
    }
}
