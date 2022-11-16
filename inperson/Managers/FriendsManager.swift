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
    static var shared: FriendsManager = .init(bluetoothManager: .shared, cryptoManager: .shared, eventsManager: .shared)
    
    let bluetoothManager: BluetoothManager
    let cryptoManager: CryptoManager
    let eventsManager: EventsManager
    
    @UserDefaultable(key: .friends) var friends: [Friend] = []
    
    var cancellables: Set<AnyCancellable> = .init()
    
    init(bluetoothManager: BluetoothManager, cryptoManager: CryptoManager, eventsManager: EventsManager) {
        self.bluetoothManager = bluetoothManager
        self.cryptoManager = cryptoManager
        self.eventsManager = eventsManager
        
        self.bluetoothManager.sendDataHandler = {
            return eventsManager.eventsToShare.encoded()
        }
        
        self.bluetoothManager.receiveDataHandler = { (uuid: UUID, data: Data) in
            guard let events = try? data.decoded(as: [Event].self), let friend = self.friend(for: uuid) else { return }
            self.eventsManager.didReceiveEvents(events, from: friend)
        }
        
//        // Sharing data when new devices are nearby
        self.bluetoothManager.$devices.didSet
            .map { [unowned self] in self.filterFriends(from: $0) }
            .flatMap { [unowned self] in
                self.getEvents(from: $0)
                    .replaceError(with: ())
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func addFriend(for id: UUID, with name: String) {
        friends.append(Friend(name: name, device: .init(id: id), publicKey: "TODO"))
    }
    
    func friend(for id: UUID) -> Friend? {
        friends.first(where: { $0.device.id == id })
    }
    
    private func filterFriends(from devices: [Device]) -> [Friend] {
        return devices.compactMap { friend(for: $0.id) }
    }
    
    private func getEvents(from nearbyFriends: [Friend]) -> AnyPublisher<Void, Error> {
         return Publishers.MergeMany(nearbyFriends.map { friend in
            self.bluetoothManager.readData(from: friend.device).flatMap { (data) -> AnyPublisher<Void, Error> in
                let decryptedData = self.cryptoManager.decryptData(data, using: friend.publicKey)
                
                do {
                    let events = try decryptedData.decoded(as: [Event].self)
                    self.eventsManager.didReceiveEvents(events, from: friend)
                    
                    return Just(())
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
        }).eraseToAnyPublisher()
    }
    
    func shareEventsWithNearbyFriends() -> AnyPublisher<Void, Error> {
        let nearbyFriends = self.filterFriends(from: bluetoothManager.devices)
        let events = eventsManager.eventsToShare.encoded()

        return Publishers.MergeMany(nearbyFriends.map { friend in
            self.bluetoothManager.writeData(events, to: friend.device)
        })
        .eraseToAnyPublisher()
//        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func clearAllData() {
        friends = []
    }
}

extension Data {
    func decoded<T: Decodable>(as decodeType: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: self)
    }
}

extension Encodable {
    func encoded() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try! encoder.encode(self)
    }
}
