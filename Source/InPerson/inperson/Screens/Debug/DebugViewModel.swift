//
//  DebugViewModel.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Combine
import Foundation

class DebugViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager
    let eventsManager: EventsManager

    @Published var debugEvents: [DebugEventInformation] = []
    private var cancellables: Set<AnyCancellable> = .init()

    init(friendsManager: FriendsManager, eventsManager: EventsManager) {
        self.friendsManager = friendsManager
        self.eventsManager = eventsManager

        super.init()

        DebugManager
            .shared
            .$events
            .map {
                $0.filter {
                    switch $0.event {
                    case .sendPush, .receivedPush, .sendingPush, .pushFailed: return true
                    default: return false
                    }
                }
            }
            .didSet
            .sink { [weak self] in
                self?.reload(events: $0)
            }
            .store(in: &cancellables)
    }

    private func reload(events: [DebugEventInformation]) {
        debugEvents = events
    }

    func clear() {
        eventsManager.clearAllData()
        friendsManager.clearAllData()
    }

    func forceSendEvents() {
        friendsManager.shareEventsWithNearbyFriends().sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
    }
}
