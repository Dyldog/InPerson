//
//  Int+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

extension Int: Sequence {

    public func makeIterator() -> CountableRange<Int>.Iterator {
        return (0 ..< self).makeIterator()
    }

    public func isLastIndex<T>(of array: [T]) -> Bool {
        return (self + 1) == array.count
    }
}
