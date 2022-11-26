//
//  String+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

extension String {

    var toASN1: Data {
        return Data(
            base64Encoded: split(separator: "\n")
                .filter { !$0.hasPrefix("-----") }
                .joined(separator: "")
        )!
    }
}
