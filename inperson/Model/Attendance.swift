//
//  Attendance.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
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
