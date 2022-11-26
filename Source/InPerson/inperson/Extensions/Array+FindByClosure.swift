//
//  Array+FindByClosure.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

extension Array {
    mutating func replaceFirst(with newElement: Element, where checker: (Element) -> Bool) {
        if let idx = firstIndex(where: checker) {
            remove(at: idx)
            insert(newElement, at: idx)
        }
    }

    mutating func removeFirst(where checker: (Element) -> Bool) {
        if let idx = firstIndex(where: checker) {
            remove(at: idx)
        }
    }
}
