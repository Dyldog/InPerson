//
//  Attendance.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import SwiftUI

enum Attendance: String, Codable, Equatable, Identifiable {
    var id: RawValue { rawValue }
    case host = "HOST"
    case going = "GOING"
    case notGoing = "NOTGOING"
    case maybe = "MAYBE"
}

extension Attendance {
    var title: String {
        switch self {
        case .going: return "Going"
        case .notGoing: return "Not Going"
        case .maybe: return "Maybe"
        case .host: return "Host"
        }
    }
    
    var emoji: String {
        switch self {
        case .host: return "👑"
        case .going: return "👍"
        case .notGoing: return "👎"
        case .maybe: return "🤔"
        }
    }
    
    var color: Color {
        switch self {
        case .host: return .blue
        case .going: return .green
        case .notGoing: return .red
        case .maybe: return .orange
        }
    }
}


extension Array where Element == Attendance {
    var summary: String {
        let counts = Dictionary(grouping: self) { $0 }
        
        var strings: [String] = []
        
        if let going = counts[.going]?.count {
            strings += ["\(going) 👍"]
        }
        
        if let notGoing = counts[.notGoing]?.count {
            strings += ["\(notGoing) 👎"]
        }
        
        if let maybe = counts[.maybe]?.count {
            strings += ["\(maybe) 🤔"]
        }
        
        if strings.isEmpty {
            strings = ["No responses"]
        }
        
        return strings.joined(separator: " ")
    }
    
    var pastSummary: String {
        let counts = Dictionary(grouping: self) { $0 }
        
        return "\(counts[.going]?.count ?? 0) people went"
    }
}
