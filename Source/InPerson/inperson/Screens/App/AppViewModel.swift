//
//  AppViewModel.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

class AppModel: NSObject, ObservableObject {
    let nearbyManager: NearbyConnectionManager
    let dataManager: DataConnectionManager
    let friendsManager: FriendsManager
    let cryptoManager: CryptoManager
    let eventsManager: EventsManager

    override init() {
        let multipeerManager = MultiPeerManager()
        nearbyManager = multipeerManager
        dataManager = multipeerManager
        cryptoManager = CryptoManager()
        eventsManager = EventsManager()

        friendsManager = .init(
            dataManager: dataManager,
            cryptoManager: cryptoManager,
            eventsManager: eventsManager,
            nearbyManager: nearbyManager
        )
    }

    func didAppear() {}

    func eventsListModel() -> EventsListViewModel {
        return .init(
            friendsManager: friendsManager,
            eventsManager: eventsManager,
            nearbyManager: nearbyManager
        )
    }

    func friendsListModel() -> FriendsListViewModel {
        return .init(
            friendsManager: friendsManager,
            nearbyManager: nearbyManager
        )
    }

    func debugViewModel() -> DebugViewModel {
        return .init(
            friendsManager: friendsManager,
            eventsManager: eventsManager
        )
    }
}
