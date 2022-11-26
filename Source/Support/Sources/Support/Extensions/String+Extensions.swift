//
//  String+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

public extension String {

    static var empty: String { return "" }

    var commaSeparated: String {
        map { String($0) }.joined(separator: ",")
    }

    /// a function that inserts a character  every N number of characters
    /// note : this function's logic will start from last index
    func insert(_ separator: Character, every stride: Int) -> String {
        return String(reversed().enumerated().map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1] }.joined().reversed())
    }
}
