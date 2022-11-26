//
//  Data+ToString.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

extension Data {
    var prettyJson: String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: self, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = String(data: data, encoding: .utf8) else { return nil }

        return prettyPrintedString
    }
}

extension Data {
    var debugString: String {
        prettyJson ?? String(data: self, encoding: .utf8) ?? "COULD NOT DECODE: \(base64EncodedString())"
    }
}
