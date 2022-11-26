//
//  Data+Decoded.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

extension Data {
    func decoded<T: Decodable>(as _: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: self)
    }
}
