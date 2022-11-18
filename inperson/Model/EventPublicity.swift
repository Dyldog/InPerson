//
//  EventPublicity.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

enum EventPublicity: Int, Codable, CaseIterable {
    case `private`
    case canInvite
    case autoShare
    
    var title: String {
        switch self {
        case .private: return "Private"
        case .canInvite: return "Invitation Allowed"
        case .autoShare: return "Public"
        }
    }
    
    var description: String {
        switch self {
        case .private: return "Only the host will be able to invite people"
        case .canInvite: return "Invitees will be able to invite specific people, but it will not be shared with friends automatically"
        case .autoShare: return "The event will be shared automatically with friends of friends (and so on)"
        }
    }
}
