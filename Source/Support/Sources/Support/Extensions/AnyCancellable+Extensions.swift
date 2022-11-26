//
//  AnyCancellable+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Combine
import Foundation

public extension Set where Element == AnyCancellable {

    /// Also known as `rangy`
    static var persistent: Set<AnyCancellable> = .init()

    func cancel() {
        forEach { $0.cancel() }
    }
}
