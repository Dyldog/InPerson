//
//  Event.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

struct Event: Codable {
    let id: UUID
    let title: String
    let date: Date
    let lastUpdate: Date
    let responses: [Response]
    let creatorID: String
    
    let invites: [Invite]
    let publicity: EventPublicity
    
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
            creatorID: creatorID,
            invites: invites,
            publicity: publicity
        )
    }
    
    func updatingInvitees(with newInvitees: [Invite]) -> Event {
        return .init(
            id: id,
            title: title,
            date: date,
            lastUpdate: .now,
            responses: responses,
            creatorID: creatorID,
            invites: newInvitees,
            publicity: publicity
        )
    }
    
    func userIsInvited(_ id: String) -> Bool {
        return invites.contains(where: { $0.recipientID == id })
    }
}

extension Array {
    func splittingPastEvents(by dateFunction: (Element) -> Date) -> (current: [Element], past: [Element]) {
        let today = Calendar.autoupdatingCurrent.startOfDay(for: .now)
        
        var current: [Element] = []
        var past: [Element] = []
        
        forEach {
            if today <= dateFunction($0) {
                current.append($0)
            } else {
                past.append($0)
            }
        }
        
        return (current, past)
    }
}
extension Array where Element == Event {
    func removingPastEvents() -> (current: [Event], past: [Event]) {
        return splittingPastEvents(by: { $0.date })
    }
    
    static var mock: [Event] {
        [
            .init(
                id: .init(),
                title: "TITLE",
                date: .now,
                lastUpdate: .now,
                responses: .mock,
                creatorID: "CREATOR_ID",
                invites: [],
                publicity: .autoShare
            )
        ]
    }
}
