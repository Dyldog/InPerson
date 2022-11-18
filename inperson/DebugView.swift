//
//  DebugView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import SwiftUI
import Combine

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
        case .connectedToDevice(let device): return "Connected to [\(device)]"
        case .disconnectedFromDevice(let device): return "Disconnected from [\(device)]"
        case .sentDataToDevice(let device, let data): return "Sent data to [\(device)]:\n\(data.prefixingLines(with: "\t"))"
        case .receivedDataFromDevice(let device, let data): return "Received data from [\(device)]:\n\(data.prefixingLines(with: "\t"))"
        case .sentInvite(device: let device): return "Sent invite to [\(device)]"
        case .notSendingInviteToUnknownPeer(let device): return "Not sending invite to unknown peer [\(device)]"
        case .receivedInvite(device: let device): return "Received invite from [\(device)]"
        case .ignoredInviteFromUnknownPeer(let device): return "Ignored invite from unknown peer [\(device)]"
        case .foundPeer(let id): return "Found peer [\(id)]"
        case .lostPeer(let id): return "Lost peer [\(id)]"
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

class DebugManager {
    static var shared: DebugManager = .init()
    
    @Published private(set) var events: [DebugEventInformation] = []
    
    func logEvent(_ event: DebugEvents) {
        DispatchQueue.main.async {
            self.events.append(.init(event: event, timestamp: .now))
        }
    }
}

extension Data {
    var prettyJson: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding:.utf8) else { return nil }

        return prettyPrintedString
    }
}

extension Data {
    var debugString: String {
        prettyJson ?? String(data: self, encoding: .utf8) ?? "COULD NOT DECODE: \(self.base64EncodedString())"
    }
}

extension String {
    func prefixingLines(with prefix: String) -> String {
        components(separatedBy: "\n").map { prefix + $0 }.joined(separator: "\n")
    }
}
class DebugViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager
    let eventsManager: EventsManager
    
    @Published var debugEvents: [DebugEventInformation] = []
    private var cancellables: Set<AnyCancellable> = .init()
    init(friendsManager: FriendsManager, eventsManager: EventsManager) {
        self.friendsManager = friendsManager
        self.eventsManager = eventsManager
        
        super.init()
        
        
        DebugManager.shared.$events.didSet.sink { [weak self] in
            self?.reload(events: $0)
        }.store(in: &cancellables)
    }
    
    func clear() {
        eventsManager.clearAllData()
        friendsManager.clearAllData()
    }
    
    func reload(events: [DebugEventInformation]) {
        debugEvents = DebugManager.shared.events
    }
}

struct DebugView: View {
    @StateObject var viewModel: DebugViewModel
    
    var body: some View {
        List {
            Section {
                Button("Clear All Data") {
                    viewModel.clear()
                }
            }
            Section {
                ForEach(viewModel.debugEvents, id: \.self) { item in
                    VStack(alignment: .leading) {
                        Text(item.timestamp.ISO8601Format())
                            .font(.footnote).foregroundColor(.gray)
                        Text(item.event.string)
                            .font(.body)
                    }
                }
            }
        }
    }
}
