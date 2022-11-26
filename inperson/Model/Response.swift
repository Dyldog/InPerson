//
//  Response.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

struct Response: Codable, Equatable {
    let responderID: String
    let going: Attendance
    let lastUpdate: Date
    
    init(responderID: String, going: Attendance, lastUpdate: Date) {
        self.responderID = responderID
        self.going = going
        self.lastUpdate = lastUpdate
    }
}

extension Array where Element == Response {
    static var mock: [Response] {
        let friends: [Friend] = .mock
        
        var responses: [Response] = []
        
        if friends.count > 0 {
            responses.append(.init(
                responderID: friends[0].device.id,
                going: .going,
                lastUpdate: .now
            ))
        }
        
        if friends.count > 1 {
            responses.append(.init(
                responderID: friends[1].device.id,
                going: .notGoing,
                lastUpdate: .now
            ))
        }
        
        if friends.count > 2 {
            responses.append(.init(
                responderID: friends[2].device.id,
                going: .maybe,
                lastUpdate: .now
            ))
        }
        
        return responses
    }
}

extension Array where Element == Response {
    var summary: String { filter { $0.responderID != userUUID }.map { $0.going}.summary }
    var pastSummary: String { filter { $0.responderID != userUUID }.map { $0.going}.pastSummary }
    
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
