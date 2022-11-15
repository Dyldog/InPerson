//
//  EventsManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation

struct Event: Codable, Equatable {
    let title: String
    let date: Date
    let lastUpdate: Date
    
    func received(from friend: Friend) -> ReceivedEvent {
        .init(event: self, sender: friend)
    }
}

struct ReceivedEvent: Codable, Equatable {
    let event: Event
    let sender: Friend
}

/// Handles:
///     - Storing created and received events
///     - Creating and editing events
class EventsManager {
    @UserDefaultable(key: .userCreatedEvents) private var myCurrentEvents: [Event] = []
    @UserDefaultable(key: .receivedEvents) private var receivedEvents: [ReceivedEvent] = []
    
    var eventsToShare: [Event] {
        myCurrentEvents + receivedEvents.map { $0.event }
    }
    
    func createEvent(_ event: Event) {
        myCurrentEvents.append(event)
    }
    
    func updateEvent(_ oldVersion: Event, with newVersion: Event) {
        myCurrentEvents.replaceFirst(with: newVersion) { $0 == oldVersion }
    }
    
    func deleteEvent(_ event: Event) {
        myCurrentEvents.removeFirst { $0 == event }
    }
    
    private func existingReceivedVersion(of event: Event) -> Event? {
        return receivedEvents.first { $0.event == event }?.event
    }
    
    private func updateReceivedEvents(with newEvents: [Event], from friend: Friend) {
        newEvents
            .filter { myCurrentEvents.contains($0) == false } // Ignore ones we created
            .forEach { received in
                // If it exists, update it if our copy is newer
                if let existing = existingReceivedVersion(of: received) {
                    if existing.lastUpdate < received.lastUpdate {
                        receivedEvents
                            .replaceFirst(with: received.received(from: friend), where: { $0.event == received })
                    }
                } else {
                    receivedEvents.append(received.received(from: friend))
                }
            }
    }
    
    func didReceiveEvents(_ events: [Event], from friend: Friend) {
        updateReceivedEvents(with: events, from: friend)
    }
}

extension Array {
    mutating func replaceFirst(with newElement: Element, where checker: (Element) -> Bool) {
        if let idx = firstIndex(where: checker) {
            remove(at: idx)
            insert(newElement, at: idx)
        }
    }
    
    mutating func removeFirst(where checker: (Element) -> Bool) {
        if let idx = firstIndex(where: checker) {
            remove(at: idx)
        }
    }
}
