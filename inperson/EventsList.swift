//
//  ContentView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI
import Combine


struct EventListItem: Identifiable {
    var id: String { title + date }
    let title: String
    let date: String
    let source: String
}

class EventsListViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager = .shared
    let eventsManager: EventsManager = .shared
    let bluetoothManager: BluetoothManager = .shared
    
    @Published var myEvents: [EventListItem] = []
    @Published var othersEvents: [EventListItem] = []
    
    @Published var isScanning: Bool = false
    var cancellables: Set<AnyCancellable> = .init()
    
    @UserDefaultable(key: .userUUID) var userUUID: UUID = .init()
    
    override init() {
        super.init()
        
        bluetoothManager.$isScanning.sink {
            self.isScanning = $0
        }
        .store(in: &cancellables)
        
        eventsManager.$eventsToShare.receive(on: RunLoop.main).sink(receiveValue: { _ in
            self.reload()
        })
        .store(in: &cancellables)
    }
    
    private func reload() {
        myEvents = eventsManager.myCurrentEvents.map {
            .init(
                title: $0.title,
                date: $0.date.ISO8601Format(),
                source: "Created by me"
            )
        }
        
        othersEvents = eventsManager.receivedEvents.map {
            let creator = friendsManager.friend(for: $0.event.creator)
            let creatorUUID = creator?.device.id ?? $0.event.creator
            
            var source = "Created by \(creator?.name ?? creatorUUID.uuidString)"
            
            if creatorUUID != $0.sender.device.id {
                source += "\nReceived from \($0.sender.name)"
            }
            
           return .init(
                title: $0.event.title,
                date: $0.event.date.ISO8601Format(),
                source: source
            )
        }
    }

    func addEvent(title: String, date: Date) {
        eventsManager.createEvent(
            .init(
                title: title,
                date: date,
                lastUpdate: .now,
                responses: [.init(responder: userUUID, going: .going)],
                creator: userUUID
            )
        )
        
        sendEvents()
    }
    
    func sendEvents() {
        friendsManager.shareEventsWithNearbyFriends().sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
    }
}

struct EventListItemView: View {
    let event: EventListItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.title)
                Text(event.date)
                    .font(.footnote)
            }
            
            Spacer()
            
            Text(event.source).font(.footnote).multilineTextAlignment(.trailing)
        }
    }
}

struct EventsList: View {
    @StateObject var viewModel: EventsListViewModel = .init()
    @State var showAddEvent: Bool = false
    
    var body: some View {
        VStack {
            List {
                Section("Mine") {
                    ForEach(viewModel.myEvents) { event in
                        EventListItemView(event: event)
                    }
                    
                    Button("Add Event") {
                        showAddEvent = true
                    }
                }
                
                Section("Others'") {
                    ForEach(viewModel.othersEvents) { event in
                        EventListItemView(event: event)
                    }
                }
            }
            
            Button("Send Events") {
                viewModel.sendEvents()
            }
        }
        .toolbar {
            Button {
                BluetoothManager.shared.scanForDevices()
            } label: {
                Circle().foregroundColor(viewModel.isScanning ? .green : .red)
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventsView() {
                viewModel.addEvent(title: $0.0, date: $0.1)
                showAddEvent = false
            }
        }
    }
}
