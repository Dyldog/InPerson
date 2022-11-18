//
//  Encodable+Encoded.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

extension Encodable {
    func encoded() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try! encoder.encode(self)
    }
}
