//
//  RequestType.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

protocol RequestType {

    var baseURL: String { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: [String: String] { get }
    var body: Encodable? { get }
    var urlRequest: URLRequest { get }
}

extension RequestType {

    var headers: [String: String] {
        return [:]
    }

    var body: Encodable? {
        return nil
    }
}

// MARK: - Internal

extension RequestType {

    var allHeaders: [String: String] {
        return headers.merging(headers) { $1 }
    }

    var urlRequest: URLRequest {
        var request: URLRequest = .init(url: URL(string: baseURL + path)!)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = allHeaders

        if let body = body {
            request.httpBody = try? body.encode()
        }

        return request
    }
}
