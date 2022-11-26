//
//  Message.swift
//  Eventful
//
//  Created by Harry Singh on 22/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

public struct Message: Codable, Hashable {
    public let from: String
    public let message: String
    public var timestamp: Double = Date.now.timeIntervalSince1970
}
