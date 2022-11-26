//
//  FriendsListViewModel.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Combine
import Foundation

class FriendsListViewModel: NSObject, ObservableObject {
    private let friendsManager: FriendsManager
    private let nearbyManager: NearbyConnectionManager

    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        return formatter
    }()

    private var cancellables: Set<AnyCancellable> = .init()

    @Published private var nearbyDevices: [Device] = []
    @Published var nearbyPeople: [FriendListItem] = []
    @Published var otherFriends: [FriendListItem] = []

    @Published var isScanning: Bool = false

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

        friendsManager.$friends.didSet.sink { _ in
            self.reload()
        }
        .store(in: &cancellables)

        nearbyManager.searchForNearbyDevices()

        reload()
    }

    private func reload() {
        nearbyPeople = nearbyDevices.map {
            let friend = self.friendsManager.friend(for: $0.id)

            return .init(
                name: friend?.name,
                id: $0.id,
                lastSeen: nil // They're within range, so we don't need the last seen
            )
        }

        otherFriends = friendsManager.friends.filter { friend in
            nearbyDevices.contains(where: { $0.id == friend.device.id }) == false
        }.map {
            .init(name: $0.name, id: $0.device.id, lastSeen: dateFormatter.string(for: $0.lastSeen))
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
