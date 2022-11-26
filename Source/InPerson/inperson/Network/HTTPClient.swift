//
//  HTTPClient.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Combine
import Foundation
import Support

public struct ErrorResponse: Codable, Equatable {
    let id: String
}

protocol HTTPClientType {

    func publisher<Response: Codable, Error: Codable & Equatable>(for request: RequestType) -> AnyPublisher<Response, HTTPError<Error>>
    func perform(_ request: RequestType, completion: @escaping TaskIn<Result<Void, HTTPError<ErrorResponse>>>)
}

final class HTTPClient: NSObject {

    // MARK: - Properties

    private var session: URLSessionType!
    private var decoder: JSONDecoder!
    private var requests: [String: TaskIn<Result<Void, HTTPError<ErrorResponse>>>] = [:]

    // MARK: - Initialisers

    init(
        session: URLSessionType = URLSession(configuration: .ephemeral),
        decoder: JSONDecoder = .init()
    ) {
        self.session = session
        self.decoder = decoder
    }
}

// MARK: - Conformance

// MARK: HTTPClientType

extension HTTPClient: HTTPClientType {

    // MARK: - Public

    public func publisher<Response: Codable, Error: Codable>(for request: RequestType) -> AnyPublisher<Response, HTTPError<Error>> {
        return session
            .dataTaskPublisher(for: request.urlRequest)
            .mapError { error -> HTTPError in
                switch error {
                case URLError.notConnectedToInternet: return .noNetwork
                case URLError.timedOut: return .timeout
                default: return .unexpected(error)
                }
            }
            .flatMap { response -> AnyPublisher<Response, HTTPError<Error>> in
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    return Fail(error: HTTPError.invalidResponse).eraseToAnyPublisher()
                }

                switch httpResponse.statusCode {
                case 200 ... 299: break
                case 401, 403: return Fail(error: .unauthorized(httpResponse.statusCode)).eraseToAnyPublisher()
                case 429: return Fail(error: .tooManyRequests).eraseToAnyPublisher()
                case 500, 400:
                    return Just(response.data)
                        .setFailureType(to: HTTPError<Error>.self)
                        .decode(type: Error.self, decoder: self.decoder)
                        .mapError { .decoder($0) }
                        .flatMap { Fail(error: .api($0)).eraseToAnyPublisher() }
                        .eraseToAnyPublisher()
                default: return Fail(error: .invalidStatusCode(httpResponse.statusCode)).eraseToAnyPublisher()
                }

                guard !response.data.isEmpty else {
                    return Fail(error: .empty).eraseToAnyPublisher()
                }

                return Just(response.data)
                    .print(String(data: response.data, encoding: .utf8)!)
                    .setFailureType(to: HTTPError<Error>.self)
                    .decode(type: Response.self, decoder: self.decoder)
                    .mapError { .decoder($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func perform(_ request: RequestType, completion: @escaping TaskIn<Result<Void, HTTPError<ErrorResponse>>>) {
        let urlSession: URLSession = session as! URLSession

        let task: URLSessionDataTask = urlSession.dataTask(with: request.urlRequest)
        requests[task.taskIdentifier.description] = completion
        task.delegate = self
        task.resume()
    }
}

extension HTTPClient: URLSessionDataDelegate {

    func urlSession(
        _: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        func send(_ response: URLSession.ResponseDisposition, _ result: Result<Void, HTTPError<ErrorResponse>>) {
            requests[dataTask.taskIdentifier.description]?(result)
            requests[dataTask.taskIdentifier.description] = nil
            completionHandler(response)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return send(.cancel, .failure(.invalidResponse))
        }

        switch httpResponse.statusCode {
        case 200 ... 299: break
        case 401, 403: return send(.cancel, .failure(.unauthorized(httpResponse.statusCode)))
        case 429: return send(.cancel, .failure(.tooManyRequests))
        case 500, 400: return send(.cancel, .failure(.api(.init(id: "ID"))))
        default: return send(.cancel, .failure(.invalidStatusCode(httpResponse.statusCode)))
        }

        print(dataTask.taskIdentifier, " - ALLOW")
        completionHandler(.allow)
    }

    func urlSession(_: URLSession, dataTask task: URLSessionDataTask, didReceive _: Data) {
        requests[task.taskIdentifier.description]?(.success(()))
        requests[task.taskIdentifier.description] = nil
        print(task.taskIdentifier, " - Success")
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            requests[task.taskIdentifier.description]?(.success(()))
            return requests[task.taskIdentifier.description] = nil
        }

        print(task.taskIdentifier, " - Error")
        print(task.taskIdentifier, " - \(error)")

        requests[task.taskIdentifier.description]?(.failure(.unexpected(error as! URLError)))
        requests[task.taskIdentifier.description] = nil
    }
}
