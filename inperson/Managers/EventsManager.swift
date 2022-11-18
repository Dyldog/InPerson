//
//  EventsManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation

enum Attendance: String, Codable, Equatable, Identifiable {
    var id: RawValue { rawValue }
    case host = "HOST"
    case going = "GOING"
    case notGoing = "NOTGOING"
    case maybe = "MAYBE"
}

extension Array where Element == Attendance {
    var summary: String {
        let counts = Dictionary(grouping: self) { $0 }
        
        var strings: [String] = []
        
        if let going = counts[.going]?.count {
            strings += ["\(going) going"]
        }
        
        if let notGoing = counts[.notGoing]?.count {
            strings += ["\(notGoing) not going"]
        }
        
        if let maybe = counts[.maybe]?.count {
            strings += ["\(maybe) maybe"]
        }
        
        if strings.isEmpty {
            strings = ["No responses"]
        }
        
        return strings.joined(separator: ", ")
    }
}

struct Response: Codable, Equatable {
    let responderID: String
    let going: Attendance
    let lastUpdate: Date
}

extension Array where Element == Response {
    var summary: String { filter { $0.responderID != userUUID }.map { $0.going}.summary }
    
    func updating(with other: [Response]) -> [Response] {
        let existing = reduce(into: [:]) { partialResult, element in
            partialResult[element.responderID] = element
        }
        
        let new = other.reduce(into: [:]) { partialResult, element in
            partialResult[element.responderID] = element
        }
        
        return Array(existing.merging(new) { (lhs: Response, rhs: Response) in
            if lhs.lastUpdate < rhs.lastUpdate {
                return rhs
            } else {
                return lhs
            }
        }.values)
    }
}

//extension Di

struct Event: Codable {
    let id: UUID
    let title: String
    let date: Date
    let lastUpdate: Date
    let responses: [Response]
    let creatorID: String
    
    func received(from friend: Friend) -> ReceivedEvent {
        .init(event: self, sender: friend)
    }
    
    func updatingResponses(with newResponses: [Response]) -> Event {
        return .init(
            id: id,
            title: title,
            date: date,
            lastUpdate: .now,
            responses: newResponses,
            creatorID: creatorID
        )
    }
}

struct ReceivedEvent: Codable {
    let event: Event
    let sender: Friend
    
    func updatingResponses(with responses: [Response]) -> ReceivedEvent {
        .init(event: event.updatingResponses(with: responses), sender: sender)
    }
}

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
