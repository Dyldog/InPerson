//
//  URLSession+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Combine
import Foundation

public protocol URLSessionType {

    func dataTaskPublisher(
        for request: URLRequest
    ) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure>
}

extension URLSession: URLSessionType {

    public func dataTaskPublisher(
        for request: URLRequest
    ) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure> {
        let publisher: URLSession.DataTaskPublisher = dataTaskPublisher(for: request)
        return publisher.eraseToAnyPublisher()
    }
}
