//
//  Friend.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

struct Friend: Codable, Equatable {
    let name: String
    let device: Device
    let publicKey: String
    var lastSeen: Date
}
