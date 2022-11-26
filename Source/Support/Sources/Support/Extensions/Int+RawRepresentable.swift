//
//  Int+RawRepresentable.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

extension Int: RawRepresentable {

    public init?(rawValue: Int) {
        self = rawValue
    }

    public var rawValue: Int { self }
}
