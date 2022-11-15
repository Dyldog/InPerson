//
//  FriendsManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import Combine

struct Friend: Codable, Equatable {
    let name: String
    let device: Device
    let publicKey: String
}

enum FriendsManagerError: Error {
    case thing
}

/// Handles:
///     - Interacting with friends
///         - Sending data
///         - Receiving data
///     - Adding new friends
class FriendsManager {
    let bluetoothManager: BluetoothManager
    let cryptoManager: CryptoManager
    let eventsManager: EventsManager
    
    @UserDefaultable(key: .friends) var friends: [Friend] = []
    
    var cancellables: Set<AnyCancellable> = .init()
    
    init(bluetoothManager: BluetoothManager, cryptoManager: CryptoManager, eventsManager: EventsManager) {
        self.bluetoothManager = bluetoothManager
        self.cryptoManager = cryptoManager
        self.eventsManager = eventsManager
        
        // Sharing data when new devices are nearby
        self.bluetoothManager.nearbyDevicesPublisher
            .map { [unowned self] in self.filterFriends(from: $0) }
            .flatMap { [unowned self] in
                self.shareEvents(with: $0)
                    .replaceError(with: ())
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Handling data we receive from other devices
        self.bluetoothManager.receivedDataPublisher
            .compactMap { [unowned self] in
                if let friend = self.friend(for: $0.1) {
                    return ($0.0, friend)
                } else {
                    return nil
                }
            }
            .sink { [unowned self] (data, friend) in
                self.didReceiveData(data, from: friend)
            }
            .store(in: &cancellables)

    }
    
    private func friend(for device: Device) -> Friend? {
        friends.first(where: { $0.device == device })
    }
    
    private func filterFriends(from devices: [Device]) -> [Friend] {
        return devices.compactMap { friend(for: $0) }
    }
    
    private func shareEvents(with nearbyFriends: [Friend]) -> AnyPublisher<Void, FriendsManagerError> {
        let eventData = cryptoManager.encryptData(eventsManager.eventsToShare.encoded())
        let sendPublishers: [AnyPublisher<Void, Error>] = nearbyFriends.map { friend in
            bluetoothManager.send(eventData, to: friend.device).eraseToAnyPublisher()
        }
        return Publishers.MergeMany(sendPublishers)
            .collect()
            .map { _ in () }
            .mapError { _ in .thing }
            .eraseToAnyPublisher()
    }
    
    func didReceiveData(_ data: Data, from friend: Friend) {
        let decryptedData = cryptoManager.decryptData(data, using: friend.publicKey)
        
        do {
            let events = try decryptedData.decoded(as: [Event].self)
            eventsManager.didReceiveEvents(events, from: friend)
        } catch {
            print(error)
        }
    }
}

extension Data {
    func decoded<T: Decodable>(as decodeType: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: self)
    }
}

extension Encodable {
    func encoded() -> Data {
        return try! JSONEncoder().encode(self)
    }
}
