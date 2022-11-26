//
//  DebugViewModel.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import Combine

class DebugViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManagerType
    let eventsManager: EventsManagerType
    
    @Published var debugEvents: [DebugEventInformation] = []
    private var cancellables: Set<AnyCancellable> = .init()
    
    init(friendsManager: FriendsManagerType, eventsManager: EventsManagerType) {
        self.friendsManager = friendsManager
        self.eventsManager = eventsManager
        
        super.init()
        
        
        DebugManager.shared.$events.didSet.sink { [weak self] in
            self?.reload(events: $0)
        }.store(in: &cancellables)
    }
    
    private func reload(events: [DebugEventInformation]) {
        debugEvents = DebugManager.shared.events
    }
    
    func clear() {
        eventsManager.clearAllData()
        friendsManager.clearAllData()
    }
    
    func forceSendEvents() {
        friendsManager.shareEventsWithNearbyFriends().sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
    }
}
