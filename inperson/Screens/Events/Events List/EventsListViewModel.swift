//
//  EventsListViewModel.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import Combine

class EventsListViewModel: NSObject, ObservableObject {
    
    private let friendsManager: FriendsManager
    private let eventsManager: EventsManager
    private let nearbyManager: NearbyConnectionManager
    
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        return formatter
    }()
    
    private var cancellables: Set<AnyCancellable> = .init()
    
    @Published var myEvents: [EventListItem] = []
    @Published var othersEvents: [EventListItem] = []
    @Published var pastEvents: [EventListItem] = []
    
    @Published var isScanning: Bool = false
    @Published var detailViewModel: EventDetailViewModel?
    @Published var showAddEvent: Bool = false
    
    init(friendsManager: FriendsManager, eventsManager: EventsManager, nearbyManager: NearbyConnectionManager) {
        self.friendsManager = friendsManager
        self.eventsManager = eventsManager
        self.nearbyManager = nearbyManager
        
        super.init()
        
        nearbyManager.isScanning.sink {
            self.isScanning = $0
        }.store(in: &cancellables)
        
        eventsManager.$eventsToShare.receive(on: RunLoop.main).sink(receiveValue: { _ in
            self.reload()
        })
        .store(in: &cancellables)
    }
    
    private func reload() {
        myEvents = eventsManager.myCurrentEvents.map {
            .init(
                id: $0.id.uuidString,
                title: $0.title,
                date: dateFormatter.string(for: $0.date) ?? .empty,
                source: "Created by me",
                responses: $0.responses.summary
            )
        }
        
        othersEvents = eventsManager.receivedEvents.map {
            let creator = friendsManager.friend(for: $0.event.creatorID)
            let creatorUUID = creator?.device.id ?? $0.event.creatorID
            
            var source = "Created by \(creator?.name ?? creatorUUID)"
            
            if creatorUUID != $0.sender.device.id {
                source += "\nReceived from \($0.sender.name)"
            }
            
           return .init(
                id: $0.event.id.uuidString,
                title: $0.event.title,
                date: dateFormatter.string(for: $0.event.date) ?? .empty,
                source: source,
                responses: $0.event.responses.summary
            )
        }
        
        pastEvents = eventsManager.pastEvents.map {
            let creator = friendsManager.friend(for: $0.creatorID)
            let creatorUUID = creator?.device.id ?? $0.creatorID
            
            var source = "Created by \(creator?.name ?? creatorUUID)"
            
            return .init(
                id: $0.id.uuidString,
                title: $0.title,
                date: dateFormatter.string(for: $0.date) ?? .empty,
                source: source,
                responses: $0.responses.pastSummary
            )
        }
    }

    func addEvent(_ details: EventCreationDetails) {
        eventsManager.createEvent(
            .init(
                id: .init(),
                title: details.title,
                date: details.date,
                lastUpdate: .now,
                responses: [],
                creatorID: userUUID,
                invites: details.invitees.map {
                    .init(senderID: userUUID, recipientID: $0.device.id)
                },
                publicity: details.publicity
            )
        )
        
        sendEvents()
    }
    
    func sendEvents() {
        friendsManager.shareEventsWithNearbyFriends().sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
    }
    
    func searchTapped() {
        nearbyManager.searchForNearbyDevices()
    }
    
    func eventTapped(_ item: EventListItem) {
        guard let event = (eventsManager.myCurrentEvents + eventsManager.receivedEvents.map { $0.event })
            .first(where: { $0.id.uuidString == item.id }) else { return }
        detailViewModel = .init(event: event, friendManager: friendsManager, eventManager: eventsManager)
    }
    
    func addEventsViewModel() -> AddEventsViewModel {
        .init(friendsManager: friendsManager, onDone: { [weak self] in
            self?.addEvent($0)
            self?.showAddEvent = false
        })
    }
}
