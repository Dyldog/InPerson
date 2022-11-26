//
//  Optional+Map.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

extension Optional {
    func map<T>(_ mapper: (Wrapped) -> T?) -> T? {
        if let self = self {
            return mapper(self)
        } else {
            return nil
        }
    }
}
