//
//  ResponseStatus.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import SwiftUI

enum ResponseStatus {
    case attendance(Attendance)
    case invited
    case host
    case notResponded
    
    var title: String {
        switch self {
        case .attendance(let attendance): return attendance.title
        case .invited: return "Invited"
        case .host: return "Host"
        case .notResponded: return "Not Responded"
        }
    }
    
    var color: Color {
        switch self {
        case .attendance(let attendance): return attendance.color
        case .invited: return .purple
        case .host: return .blue
        case .notResponded: return .gray
        }
    }
}
