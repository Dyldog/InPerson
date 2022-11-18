//
//  DebugViewModel.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import Combine

class DebugViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager
    let eventsManager: EventsManager
    
    @Published var debugEvents: [DebugEventInformation] = []
    private var cancellables: Set<AnyCancellable> = .init()
    init(friendsManager: FriendsManager, eventsManager: EventsManager) {
        self.friendsManager = friendsManager
        self.eventsManager = eventsManager
        
        super.init()
        
        
        DebugManager.shared.$events.didSet.sink { [weak self] in
            self?.reload(events: $0)
        }.store(in: &cancellables)
    }
    
    func clear() {
        eventsManager.clearAllData()
        friendsManager.clearAllData()
    }
    
    func reload(events: [DebugEventInformation]) {
        debugEvents = DebugManager.shared.events
    }
}
