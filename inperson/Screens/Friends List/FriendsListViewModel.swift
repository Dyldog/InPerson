//
//  FriendsListViewModel.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import Combine

class FriendsListViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager
    let nearbyManager: NearbyConnectionManager
    
    @Published private var nearbyDevices: [Device] = []
    @Published var nearbyPeople: [FriendListItem] = []
    @Published var otherFriends: [FriendListItem] = []
    
    @Published var isScanning: Bool = false
    
    var cancellables: Set<AnyCancellable> = .init()
    
    init(friendsManager: FriendsManager, nearbyManager: NearbyConnectionManager) {
        self.friendsManager = friendsManager
        self.nearbyManager = nearbyManager
        
        super.init()
        
        nearbyManager.isScanning.sink {
            self.isScanning = $0
        }.store(in: &cancellables)
        
        nearbyManager.nearbyDevices.didSet.receive(on: RunLoop.main).sink { peripherals in
            self.nearbyDevices = peripherals
            self.reload()
        }
        .store(in: &cancellables)
        
        friendsManager.$friends.didSet.sink { friends in
            self.reload()
        }
        .store(in: &cancellables)
        
        nearbyManager.searchForNearbyDevices()
        
        reload()
    }
    
    private func reload() {
        nearbyPeople = nearbyDevices.map {
            .init(name: self.friendsManager.friend(for: $0.id)?.name, id: $0.id)
        }
        
        otherFriends = friendsManager.friends.filter { friend in
            nearbyDevices.contains(where: { $0.id == friend.device.id }) == false
        }.map {
            .init(name: $0.name, id: $0.device.id)
        }
    }
    
    func addFriend(_ uuid: String) {
        guard friendsManager.friend(for: uuid) == nil else { return }
//        friendsManager.addFriend(for: uuid, with: name, and: device)
        
        nearbyManager.initiateConnection(with: .init(id: uuid))
        reload()
    }
    
    func searchTapped() {
        nearbyManager.searchForNearbyDevices()
    }
}
