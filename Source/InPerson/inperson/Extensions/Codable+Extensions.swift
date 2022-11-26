//
//  Codable+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

extension Encodable {

    func encode() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}
