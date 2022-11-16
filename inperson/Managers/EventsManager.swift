//
//  EventsManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation

enum Attendance: Codable, Equatable {
    case going
    case notGoing
    case maybe
}

struct Response: Codable, Equatable {
    let responder: UUID
    let going: Attendance
}

struct Event: Codable, Equatable {
    let title: String
    let date: Date
    let lastUpdate: Date
    let responses: [Response]
    let creator: UUID
    
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
    static var shared: EventsManager = .init()
    
    @UserDefaultable(key: .userCreatedEvents) private(set) var myCurrentEvents: [Event] = [] {
        didSet { reload() }
    }
    @UserDefaultable(key: .receivedEvents) private(set) var receivedEvents: [ReceivedEvent] = [] {
        didSet { reload() }
    }
    
    @UserDefaultable(key: .userUUID) var userUUID: UUID = .init()
    
    @Published var eventsToShare: [Event] = []
    
    init() {
        reload()
    }
    
    private func reload() {
        eventsToShare = myCurrentEvents + receivedEvents.map { $0.event }
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
                // If it's our event, we need to be more careful with how we update it
                if received.creator == userUUID {
                    // TODO: Update own event
                } else if let existing = existingReceivedVersion(of: received) {
                    // If it exists, update it if our copy is newer
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
    
    func clearAllData() {
        myCurrentEvents = []
        receivedEvents = []
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
