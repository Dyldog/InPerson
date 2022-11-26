//
//  PushService.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Combine
import CommonCrypto
import Foundation
import Support
import UIKit
import UserNotifications

public struct EmptyResponse: Codable {}

public struct PushError: Codable, Equatable {
    let reason: String
    let timestamp: Date?
}

public final class PushService {

    public final class Request: Codable {

        public enum State: Int, Codable, Hashable {
            case sending = 0
            case sent
            case cancelled
            case received
        }

        public let id: UUID
        public var state: State
        public let message: Message

        init(id: UUID = .init(), state: State = .sending, message: Message) {
            self.id = id
            self.state = state
            self.message = message
        }
    }

    // MARK: - Properties

    public static let shared: PushService = .init()

    var receiveDataHandler: ((String, Data) -> Void)?

    private let client: HTTPClientType
    private(set) var teamID: String!
    private(set) var cert: String!
    private(set) var authKeyID: String!
    private(set) var topic: String!
    @UserDefaultable(key: .pushToken) private(set) var token: String = ""
    private var cancellable: Set<AnyCancellable> = .init()

    // MARK: - Initialisers

    init(client: HTTPClientType = HTTPClient()) {
        self.client = client
    }
}

// MARK: - Public

public extension PushService {

    var values: AnyPublisher<[Request], Never> {
        return UserDefaults.standard.publisher(for: \.requests)
            .compactMap { try? $0.compactMap { try JSONDecoder().decode(Request.self, from: $0) }}
            .combineLatest(devices)
            .map { requests, devices in
                requests.map { request in
                    guard let device = devices.first(where: { $0.token == request.message.from }) else {
                        return request
                    }

                    return Request(
                        id: request.id,
                        state: request.state,
                        message: Message(from: device.name, message: request.message.message, timestamp: request.message.timestamp)
                    )
                }
                .sorted { $0.message.timestamp < $1.message.timestamp }
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var devices: AnyPublisher<[Device1], Never> {
        return UserDefaults
            .standard
            .publisher(for: \.devices)
            .compactMap { try? $0.compactMap { try JSONDecoder().decode(Device1.self, from: $0) }}
            .map {
                $0.isEmpty
                    ? [
                        .init(
                            name: "Harry: iPhone 6s+",
                            token: "1a6f28d7107476e59d97e6b82574b18b814574d15de2374f3a89de7930cd7d51"
                        ),
                        .init(
                            name: "Harry: iPhone 12 Pro Max",
                            token: "c4f455e58199d60824dd480644ecd317f71a954ef94b04684d9aea9af4ebc26e"
                        ),
                    ]
                    : $0
            }
            .print()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func set(teamID: String, cert: String, authKeyID: String, topic: String) {
        self.teamID = teamID
        self.cert = cert
        self.authKeyID = authKeyID
        self.topic = topic
    }

    func set(token: String) {
        self.token = token
    }

    func add(_ device: Device1) {
        guard let data = try? device.encode() else {
            return
        }

        let devices: NSMutableOrderedSet = .init(array: UserDefaults.standard.devices)
        devices.add(data)
        UserDefaults.standard.devices = devices.array as! [Data]
    }

    func remove(_ device: Device1) {
        guard let data = try? device.encode() else {
            return
        }

        UserDefaults.standard.devices = UserDefaults.standard.devices.filter { $0 != data }
    }

    func send(_ message: String, to token: String) {
        let message: Message = .init(from: self.token, message: message)

        let pushRequest: PushRequest = .init(
            teamID: teamID,
            cert: cert,
            authKeyID: authKeyID,
            topic: topic,
            token: token,
            body: message
        )

        let request: Request = .init(message: message)

        DebugManager.shared.logEvent(.sendPush(message: message.message, to: token))

        add(request)
        perform(pushRequest)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure: request.state = .sending
                    case .finished: request.state = .sent
                    }

                    DebugManager.shared.logEvent(.pushFailed(message: message.message, to: token))
                    self?.update(request)
                },
                receiveCancel: { [weak self] in
                    request.state = .cancelled
                    self?.update(request)
                }
            )
            .retry(delay: .after(seconds: 60), scheduler: DispatchQueue.global())
            .sink(
                receiveCompletion: { _ in
                    // Error
                },
                receiveValue: { _ in
                    // Success
                }
            )
            .store(in: &cancellable)
    }

    func requestAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else {
                return print("Rejected")
            }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    @discardableResult
    func received(_ notification: [AnyHashable: Any]) -> Bool {
        let jsonData: Data? = try? JSONSerialization.data(withJSONObject: notification, options: .prettyPrinted)

        guard
            let jsonData = jsonData,
            let message: PushRequest.Body<Message> = try? JSONDecoder().decode(PushRequest.Body<Message>.self, from: jsonData),
            let data = try? Request(state: .received, message: message.message).encode()
        else {
            print(notification)
            return false
        }

        var notifications: [Data] = UserDefaults.standard.requests
        notifications.append(data)

        UserDefaults.standard.requests = notifications

        let content: UNMutableNotificationContent = .init()
        content.title = "Eventful"
        content.subtitle = message.message.from
        content.body = message.message.message

        UNUserNotificationCenter.current().add(.init(identifier: UUID().uuidString, content: content, trigger: nil))

        receiveDataHandler?(message.message.from, jsonData)

        DebugManager.shared.logEvent(
            .receivedPush(message: message.message.message, from: message.message.from)
        )
        return true
    }
}

// MARK: - Private

private extension PushService {

    func add(_ request: Request) {
        guard let data: Data = try? JSONEncoder().encode(request) else {
            fatalError()
        }

        var requests: [Data] = UserDefaults.standard.requests
        requests.append(data)
        UserDefaults.standard.requests = requests
    }

    func update(_ request: Request) {
        guard
            var requests: [Request] = (try? UserDefaults.standard.requests.map { try JSONDecoder().decode(Request.self, from: $0) }),
            let index: Int = requests.firstIndex(where: { $0.id == request.id })
        else {
            fatalError()
        }

        requests.remove(at: index)
        requests.insert(request, at: index)

        UserDefaults.standard.requests = try! requests.map { try JSONEncoder().encode($0) }
    }

    func perform(_ request: PushRequest) -> AnyPublisher<Void, HTTPError<PushError>> {
        let publisher: AnyPublisher<EmptyResponse, HTTPError<PushError>> = client.publisher(for: request)

        return publisher
            .map { _ in () }
            .tryCatch { error -> AnyPublisher<Void, HTTPError<PushError>> in
                guard error == .empty else {
                    throw error
                }

                return Just(()).setFailureType(to: HTTPError<PushError>.self).eraseToAnyPublisher()
            }
            .mapError { $0 as! HTTPError<PushError> }
            .eraseToAnyPublisher()
    }
}

extension PushService: DataConnectionManager {

    var connectedDevices: AnyPublisher<[Device], Never> {
        return Just([]).eraseToAnyPublisher()
    }

    func writeData(_ data: Data, to device: Device) -> AnyPublisher<Void, Error> {
        DebugManager.shared.logEvent(
            .sendingPush(message: String(data: data, encoding: .utf8) ?? "FAILED TO DECODE", to: device.pushToken)
        )

        return Just(
            send(String(data: data, encoding: .utf8) ?? "FAILED TO DECODE", to: device.pushToken)
        )
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
}
