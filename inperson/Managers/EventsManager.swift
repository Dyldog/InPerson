//
//  EventsManagerType.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import Combine

protocol EventsManagerType {
    func clearAllData()
    func didReceiveEvents(_ events: [Event], from friend: Friend)
    func createEvent(_ event: Event)
    func updateEvent(_ oldVersion: Event, with newVersion: Event)
    func updateEvent(_ event: Event, with responses: [Response])
    
    var eventsToShare: [Event] { get }
    var eventsToSharePublisher: AnyPublisher<[Event], Never> { get }
    
    var myCurrentEvents: [Event] { get }
    var receivedEvents: [ReceivedEvent] { get }
    var pastEvents: [Event] { get }
    
    func inviteFriends(_ invitees: [Friend], to event: Event) -> Event?
}

class MockEventsManager: EventsManagerType {
    
    @Published var eventsToShare: [Event] = []
    var eventsToSharePublisher: AnyPublisher<[Event], Never> { $eventsToShare.eraseToAnyPublisher() }
    
    var myCurrentEvents: [Event] = []
    var receivedEvents: [ReceivedEvent] = []
    var pastEvents: [Event] = []
    
    init(myCurrentEvents: [Event], receivedEvents: [ReceivedEvent], pastEvents: [Event]) {
        self.myCurrentEvents = myCurrentEvents
        self.receivedEvents = receivedEvents
        self.pastEvents = pastEvents
    }
    
    func clearAllData() {
        //
    }
    
    func didReceiveEvents(_ events: [Event], from friend: Friend) {
        //
    }
    
    func createEvent(_ event: Event) {
        //
    }
    
    func updateEvent(_ oldVersion: Event, with newVersion: Event) {
        //
    }
    
    func updateEvent(_ event: Event, with responses: [Response]) {
        //
    }
    
    func inviteFriends(_ invitees: [Friend], to event: Event) -> Event? {
        return .init(
            id: event.id,
            title: event.title,
            date: event.date,
            lastUpdate: event.lastUpdate,
            responses: event.responses,
            creatorID: event.creatorID,
            invites: event.invites + invitees.map { .init(senderID: "MEEEEE", recipientID: $0.device.id) },
            publicity: event.publicity
        )
    }
}

/// Handles:
///     - Storing created and received events
///     - Creating and editing events
class EventsManager: EventsManagerType {
    
    @UserDefaultable(key: .userCreatedEvents) private(set) var myCurrentEvents: [Event] = [] {
        didSet { reload() }
    }
    @UserDefaultable(key: .receivedEvents) private(set) var receivedEvents: [ReceivedEvent] = [] {
        didSet { reload() }
    }
    @UserDefaultable(key: .pastEvents) private(set) var pastEvents: [Event] = []
    
    @Published var eventsToShare: [Event] = []
    var eventsToSharePublisher: AnyPublisher<[Event], Never> { $eventsToShare.eraseToAnyPublisher() }
    
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
    
    private func newInvitesList(for event: Event, with invitees: [Invite]) -> [Invite] {
        event.invites + invitees.filter { event.userIsInvited($0.recipientID) == false }
    }
    
    func inviteFriends(_ invitees: [Friend], to event: Event) -> Event? {
        let invites: [Invite] = invitees.map { .init(senderID: userUUID, recipientID: $0.device.id) }
        
        if let existing = existingCreatedVersion(of: event) {
            let new = existing.updatingInvitees(with: newInvitesList(for: event, with: invites))
            myCurrentEvents.replaceFirst(
                with: new,
                where: { $0.id == event.id }
            )
            reload()
            return new
        } else if let existing = existingReceivedVersion(of: event) {
            let new = existing.updatingInvitees(with: newInvitesList(for: event, with: invites))
            receivedEvents.replaceFirst(
                with: new,
                where: { $0.event.id == event.id }
            )
            reload()
            return new.event
        } else {
            reload()
            return nil
        }
    }
    
    func didReceiveEvents(_ events: [Event], from friend: Friend) {
        updateReceivedEvents(with: events, from: friend)
    }
    
    func clearAllData() {
        myCurrentEvents = []
        receivedEvents = []
        pastEvents = []
    }
}
