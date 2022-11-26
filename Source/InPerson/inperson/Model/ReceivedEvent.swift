//
//  ReceivedEvent.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

struct ReceivedEvent: Codable {
    let event: Event
    let sender: Friend

    func updatingResponses(with responses: [Response]) -> ReceivedEvent {
        .init(event: event.updatingResponses(with: responses), sender: sender)
    }

    func updatingInvitees(with newInvitees: [Invite]) -> ReceivedEvent {
        return .init(event: event.updatingInvitees(with: newInvitees), sender: sender)
    }
}

extension Array where Element == ReceivedEvent {
    func splittingPastEvents() -> (current: [ReceivedEvent], past: [ReceivedEvent]) {
        return splittingPastEvents(by: { $0.event.date })
    }
}
