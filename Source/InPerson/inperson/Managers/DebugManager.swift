//
//  DebugManager.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

class DebugManager {
    static var shared: DebugManager = .init()

    @Published private(set) var events: [DebugEventInformation] = []

    func logEvent(_ event: DebugEvents) {
        DispatchQueue.main.async {
            self.events.append(.init(event: event, timestamp: .now))
        }
    }
}
