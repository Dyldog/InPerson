//
//  Device.swift
//  Eventful
//
//  Created by Harry Singh on 22/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

public struct Device1: Codable, Hashable {
    public let name: String
    public let token: String

    public init(name: String, token: String) {
        self.name = name
        self.token = token
    }
}
