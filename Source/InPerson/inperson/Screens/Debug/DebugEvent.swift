//
//  DebugEvent.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation

enum DebugEvents: Hashable, Equatable {
    case connectedToDevice(device: String)
    case disconnectedFromDevice(device: String)

    case sentDataToDevice(device: String, data: String)
    case receivedDataFromDevice(device: String, data: String)

    case sentInvite(device: String)
    case notSendingInviteToUnknownPeer(device: String)
    case receivedInvite(device: String)
    case ignoredInviteFromUnknownPeer(device: String)

    case foundPeer(id: String)
    case lostPeer(id: String)

    var string: String {
        switch self {
        case let .connectedToDevice(device): return "Connected to [\(device)]"
        case let .disconnectedFromDevice(device): return "Disconnected from [\(device)]"
        case let .sentDataToDevice(device, data): return "Sent data to [\(device)]:\n\(data.prefixingLines(with: "\t"))"
        case let .receivedDataFromDevice(device, data): return "Received data from [\(device)]:\n\(data.prefixingLines(with: "\t"))"
        case let .sentInvite(device: device): return "Sent invite to [\(device)]"
        case let .notSendingInviteToUnknownPeer(device): return "Not sending invite to unknown peer [\(device)]"
        case let .receivedInvite(device: device): return "Received invite from [\(device)]"
        case let .ignoredInviteFromUnknownPeer(device): return "Ignored invite from unknown peer [\(device)]"
        case let .foundPeer(id): return "Found peer [\(id)]"
        case let .lostPeer(id): return "Lost peer [\(id)]"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(string)
    }
}

struct DebugEventInformation: Hashable {
    let event: DebugEvents
    let timestamp: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(event.string)
        hasher.combine(timestamp)
    }
}
