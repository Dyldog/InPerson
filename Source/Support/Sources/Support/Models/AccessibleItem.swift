//
//  AccessibleItem.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

public struct AccessibleItem: Equatable, Hashable, ExpressibleByStringLiteral {

    public typealias StringLiteralType = String

    public let title: String
    public let accessibilityLabel: String
    public let accessibilityHint: String?

    public init(title: String, accessibilityLabel: String? = nil, accessibilityHint: String? = nil) {
        self.title = title
        self.accessibilityLabel = accessibilityLabel ?? title
        self.accessibilityHint = accessibilityHint
    }

    public init(stringLiteral: String) {
        self.init(title: stringLiteral, accessibilityLabel: nil, accessibilityHint: nil)
    }
}
