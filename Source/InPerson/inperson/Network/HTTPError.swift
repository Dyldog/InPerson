//
//  HTTPError.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

public enum HTTPError<T: Codable & Equatable>: Error, Equatable {
    case timeout
    case noNetwork
    case invalidResponse
    case unauthorized(Int)
    case tooManyRequests
    case invalidStatusCode(Int)
    case api(T)
    case decoder(Error)
    case unexpected(URLError)
    case empty

    public static func == (lhs: HTTPError, rhs: HTTPError) -> Bool {
        switch (lhs, rhs) {
        case (.timeout, .timeout),
             (.noNetwork, .noNetwork),
             (.tooManyRequests, .tooManyRequests),
             (.invalidResponse, .invalidResponse),
             (.empty, .empty): return true
        case let (.unauthorized(lhsCode), .unauthorized(rhsCode)): return lhsCode == rhsCode
        case let (.invalidStatusCode(lhsCode), .invalidStatusCode(rhsCode)): return lhsCode == rhsCode
        case let (.api(lhsError), .api(rhsError)): return lhsError == rhsError
        case let (.decoder(lhsError), .decoder(rhsError)): return lhsError as NSError == rhsError as NSError
        case let (.unexpected(lhsError), .unexpected(rhsError)): return lhsError == rhsError
        default: return false
        }
    }
}
