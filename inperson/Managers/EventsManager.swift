//
//  EventsManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation

/// Handles:
///     - Storing created and received events
///     - Creating and editing events
class EventsManager {
    
    @UserDefaultable(key: .userCreatedEvents) private(set) var myCurrentEvents: [Event] = [] {
        didSet { reload() }
    }
    @UserDefaultable(key: .receivedEvents) private(set) var receivedEvents: [ReceivedEvent] = [] {
        didSet { reload() }
    }
    @UserDefaultable(key: .pastEvents) private(set) var pastEvents: [Event] = [] {
        didSet { reload() }
    }
    
    @Published var eventsToShare: [Event] = []
    
    init() {
        reload()
    }
    
    private func reload() {
        let mine = myCurrentEvents.removingPastEvents()
        let others = receivedEvents.splittingPastEvents()
        
        // Note: The didSets on `myCurrentEvents` and `receivedEvents` will trigger `reload()` to be
        // called again
        if !mine.past.isEmpty {
            pastEvents.append(contentsOf: mine.past)
            myCurrentEvents = mine.current
        } else if !others.past.isEmpty {
            pastEvents.append(contentsOf: others.past.map { $0.event })
            receivedEvents = others.current
        } else {
            eventsToShare = myCurrentEvents + receivedEvents.map { $0.event }
        }
    }
    func createEvent(_ event: Event) {
        myCurrentEvents.append(event)
    }
    
    func updateEvent(_ oldVersion: Event, with newVersion: Event) {
        myCurrentEvents.replaceFirst(with: newVersion) { $0.id == oldVersion.id }
    }
    
    func deleteEvent(_ event: Event) {
        myCurrentEvents.removeFirst { $0.id == event.id }
    }
    
    private func existingCreatedVersion(of event: Event) -> Event? {
        return myCurrentEvents.first { $0.id == event.id }
    }
    
    private func existingReceivedVersion(of event: Event) -> ReceivedEvent? {
        return receivedEvents.first { $0.event.id == event.id }
    }
    
    private func updateReceivedEvents(with newEvents: [Event], from friend: Friend) {
        newEvents
            .forEach { received in
                // If it's our event, we need to be more careful with how we update it
                if let existing = existingCreatedVersion(of: received) {
                    myCurrentEvents.replaceFirst(
                        with: existing.updatingResponses(with: received.responses),
                        where: { $0.id == received.id }
                    )
                } else if let existing = existingReceivedVersion(of: received) {
                    // If it exists, update it if our copy is newer
                    if existing.event.lastUpdate < received.lastUpdate {
                        receivedEvents
                            .replaceFirst(with: received.received(from: friend), where: { $0.event.id == received.id })
                    }
                } else {
                    receivedEvents.append(received.received(from: friend))
                }
                
                reload()
            }
    }
    
    func updateEvent(_ event: Event, with responses: [Response]) {
        if let existing = existingCreatedVersion(of: event) {
            myCurrentEvents.replaceFirst(
                with: existing.updatingResponses(with: responses),
                where: { $0.id == event.id }
            )
        } else if let existing = existingReceivedVersion(of: event) {
            receivedEvents.replaceFirst(
                with: existing.updatingResponses(with: responses),
                where: { $0.event.id == event.id }
            )
        }
        
        reload()
    }
    
    func didReceiveEvents(_ events: [Event], from friend: Friend) {
        updateReceivedEvents(with: events, from: friend)
    }
    
    func clearAllData() {
        myCurrentEvents = []
        receivedEvents = []
    }
}
