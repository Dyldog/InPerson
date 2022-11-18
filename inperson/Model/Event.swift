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
