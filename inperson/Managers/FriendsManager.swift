//
//  FriendsManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import Combine
import UIKit

enum FriendsManagerError: Error {
    case thing
}

/// Handles:
///     - Interacting with friends
///         - Sending data
///         - Receiving data
///     - Adding new friends
class FriendsManager {
    
    let nearbyManager: NearbyConnectionManager
    var dataManager: DataConnectionManager
    let cryptoManager: CryptoManager
    let eventsManager: EventsManager
    
    @UserDefaultable(key: .userUUID) var userUUID: String = UUID().uuidString
    @Published  var friends: [Friend] = UserDefaults.standard.decodable(for: .friends) ?? [] {
        didSet {
            UserDefaults.standard.set(data: friends.encoded(), for: .friends)
        }
    }
    
    var connectableDevices: [Device] = []
    var cancellables: Set<AnyCancellable> = .init()
    
    init(dataManager: DataConnectionManager, cryptoManager: CryptoManager, eventsManager: EventsManager, nearbyManager: NearbyConnectionManager) {
        self.nearbyManager = nearbyManager
        self.dataManager = dataManager
        self.cryptoManager = cryptoManager
        self.eventsManager = eventsManager
        
        self.dataManager.onInviteHandler = { [weak self] id, completion in
            self?.onInvite(id: id, completion: completion)
        }
        
        self.dataManager.onConnectHandler = { [weak self] in
            guard let self = self else { return }
            self.nearbyManager.initiateConnection(with: $0)
            self.dataManager.writeData(eventsManager.eventsToShare.encoded(), to: $0).sink(receiveCompletion: { _ in
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
            nearDevices.filter { self.connectableDevices.contains($0) == false }.forEach {
                self.nearbyManager.initiateConnection(with: $0)
            }
        }
        .store(in: &cancellables)

        self.dataManager.connectableDevices.didSet.sink { _ in
            //
        } receiveValue: { devices in
            self.connectableDevices = devices
        }.store(in: &cancellables)
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
        
        if friend(for: id) != nil {
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
        friends.append(Friend(name: name, device: device, publicKey: "TODO"))
    }
    
    func friend(for id: String) -> Friend? {
        friends.first(where: { $0.device.id == id })
    }
    
    private func filterFriends(from devices: [Device]) -> [Friend] {
        return devices.compactMap { friend(for: $0.id) }
    }
    
    func shareEventsWithNearbyFriends() -> AnyPublisher<Void, Error> {
        let nearbyFriends = self.filterFriends(from: connectableDevices)
        
        guard !nearbyFriends.isEmpty else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        let events = eventsManager.eventsToShare.encoded()

        return self.dataManager.writeData(events, to: nearbyFriends.first!.device).eraseToAnyPublisher()
    }
    
    func clearAllData() {
        friends = []
    }
}
