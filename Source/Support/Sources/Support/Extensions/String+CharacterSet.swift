//
//  String+CharacterSet.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

public extension String {
    func removingCharacters(in characterSet: CharacterSet) -> String {
        components(separatedBy: characterSet).joined()
    }

    func keepingOnlyCharacters(in characterSet: CharacterSet) -> String {
        removingCharacters(in: characterSet.inverted)
    }
}
