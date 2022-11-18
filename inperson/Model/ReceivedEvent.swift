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
}
