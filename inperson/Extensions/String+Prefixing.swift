//
//  String+Prefixing.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

extension String {
    func prefixingLines(with prefix: String) -> String {
        components(separatedBy: "\n").map { prefix + $0 }.joined(separator: "\n")
    }
}
