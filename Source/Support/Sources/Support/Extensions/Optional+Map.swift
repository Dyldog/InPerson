//
//  Optional+Map.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

extension Optional {
    func map<T>(_ applying: (Wrapped) -> T) -> T? {
        switch self {
        case .none: return nil
        case let .some(wrapped): return applying(wrapped)
        }
    }
}
