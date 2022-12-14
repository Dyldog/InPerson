//
//  FriendsManagerType.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import Combine
import UIKit

protocol FriendsManagerType {
    var friends: [Friend] { get }
    var friendsPublisher: AnyPublisher<[Friend], Never> { get }
    func clearAllData()
    func shareEventsWithNearbyFriends() -> AnyPublisher<Void, Error>
}

extension FriendsManagerType {
    func friend(for id: String) -> Friend? {
        friends.first(where: { $0.device.id == id })
    }
}

extension Array where Element == Friend {
    static var mock: [Friend] = [
        .init(name: "Dylan", device: .init(id: "DYLAN"), publicKey: "", lastSeen: .now),
        .init(name: "Harry", device: .init(id: "HARRY"), publicKey: "", lastSeen: .now),
        .init(name: "Swati", device: .init(id: "SWATI"), publicKey: "", lastSeen: .now),
    ]
}
class MockFriendsManager: FriendsManagerType {
    @Published var friends: [Friend] = []
    var friendsPublisher: AnyPublisher<[Friend], Never> { $friends.eraseToAnyPublisher() }
    
    init(friends: [Friend] = []) {
        self.friends = friends
    }
    func clearAllData() { }
    
    func shareEventsWithNearbyFriends() -> AnyPublisher<Void, Error> {
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
}

enum FriendsManagerError: Error {
    case thing
}

/// Handles:
///     - Interacting with friends
///         - Sending data
///         - Receiving data
///     - Adding new friends
class FriendsManager: FriendsManagerType {
    
    let nearbyManager: NearbyConnectionManager
    var dataManager: DataConnectionManager
    let cryptoManager: CryptoManager
    let eventsManager: EventsManagerType
    
    @UserDefaultable(key: .userUUID) var userUUID: String = UUID().uuidString
    @Published  var friends: [Friend] = UserDefaults.standard.decodable(for: .friends) ?? [] {
        didSet {
            UserDefaults.standard.set(data: friends.encoded(), for: .friends)
        }
    }
    
    var friendsPublisher: AnyPublisher<[Friend], Never> { $friends.eraseToAnyPublisher() }
    
    var connectableDevices: [Device] = []
    var cancellables: Set<AnyCancellable> = .init()
    
    init(dataManager: DataConnectionManager, cryptoManager: CryptoManager, eventsManager: EventsManagerType, nearbyManager: NearbyConnectionManager) {
        self.nearbyManager = nearbyManager
        self.dataManager = dataManager
        self.cryptoManager = cryptoManager
        self.eventsManager = eventsManager
        
        self.dataManager.onInviteHandler = { [weak self] id, completion in
            self?.onInvite(id: id, completion: completion)
        }
        
        self.dataManager.onConnectHandler = { [weak self] in
            guard let self = self, let friend = self.friend(for: $0.id) else { return }
            self.updateLastSeen(for: friend)
            
            if self.connectableDevices.contains($0) == false {
                nearbyManager.initiateConnection(with: $0)
            }
            
            self.shareEvents(with: friend).sink(receiveCompletion: { _ in
                //
            }, receiveValue: { _ in
                //
            })
            .store(in: &self.cancellables)
        }

        self.dataManager.receiveDataHandler = { (uuid: String, data: Data) in
            guard let events = try? data.decoded(as: [Event].self), let friend = self.friend(for: uuid) else { return }
            self.eventsManager.didReceiveEvents(events, from: friend)
        }
        
        self.nearbyManager.nearbyDevices.didSet.sink { nearDevices in
            self.filterFriends(from: nearDevices).forEach {
                self.nearbyManager.initiateConnection(with: $0.device)
            }
        }
        .store(in: &cancellables)

        self.dataManager.connectedDevices.didSet.sink { _ in
            //
        } receiveValue: { devices in
            self.connectableDevices = devices
        }.store(in: &cancellables)
    }
    
    private func updateLastSeen(for friend: Friend) {
        guard let index = friends.firstIndex(where: { $0.device.id == friend.device.id }) else { return }
        friends[index].lastSeen = .now
    }
    
    private func getName(for id: String) {
        let alert = UIAlertController(title: "What's their name?", message: nil, preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(.init(title: "Add", style: .default, handler: { action in
            guard let name = alert.textFields?.first?.text else { return }
            self.addFriend(for: id, with: name, and: .init(id: id))
        }))
        
        UIApplication.shared.showAlert(alert)
    }
    
    private func onInvite(id: String, completion: @escaping (Bool) -> Void) {
        
        if let friend = friend(for: id) {
            updateLastSeen(for: friend)
            completion(true)
        } else {
            let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Invitation Received"

            let ac = UIAlertController(title: appName, message: "'\(id)' wants to connect.", preferredStyle: .alert)
            let declineAction = UIAlertAction(title: "Decline", style: .cancel) { _ in
                completion(false)
            }
            let acceptAction = UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
                completion(true)
                
                ac.dismiss(animated: true) {
                    self?.getName(for: id)
                }
            }
            
            ac.addAction(declineAction)
            ac.addAction(acceptAction)
            
            UIApplication.shared.showAlert(ac)
        }
    }
    
    func addFriend(for id: String, with name: String, and device: Device) {
        friends.append(Friend(name: name, device: device, publicKey: "TODO", lastSeen: .now))
    }
    
    private func filterFriends(from devices: [Device]) -> [Friend] {
        return devices.compactMap { friend(for: $0.id) }
    }
    
    private func filterEvents(_ events: [Event], for friend: Friend) -> [Event] {
        return events.filter { event in
            switch event.publicity {
            case .private, .canInvite:
                return event.creatorID == friend.device.id || event.invites.contains(where: { $0.recipientID == friend.device.id })
            case .autoShare: return true
            }
        }
    }
    
    private func shareEvents(with friend: Friend) -> AnyPublisher<Void, Error>{
        let events = filterEvents(eventsManager.eventsToShare, for: friend)
        return self.dataManager.writeData(events.encoded(), to: friend.device)
    }
    func shareEventsWithNearbyFriends() -> AnyPublisher<Void, Error> {
        let nearbyFriends = self.filterFriends(from: connectableDevices)
        
        return Publishers.MergeMany(
            nearbyFriends.map {
                self.shareEvents(with: $0)
            }
        )
        .collect().map { _ in () }.eraseToAnyPublisher()
    }
    
    func clearAllData() {
        friends = []
    }
}
