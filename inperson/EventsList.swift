//
//  ContentView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI
import Combine


struct EventListItem: Identifiable {
    var id: String
    let title: String
    let date: String
    let source: String
    let responses: String
}

var userUUID: String = UIDevice.current.identifierForVendor?.uuidString ?? "ERROR!!!"

class EventsListViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager
    let eventsManager: EventsManager
    let nearbyManager: NearbyConnectionManager
    
    @Published var myEvents: [EventListItem] = []
    @Published var othersEvents: [EventListItem] = []
    
    @Published var isScanning: Bool = false
    var cancellables: Set<AnyCancellable> = .init()
    
    @Published var detailViewModel: EventDetailViewModel?
    
    init(friendsManager: FriendsManager, eventsManager: EventsManager, nearbyManager: NearbyConnectionManager) {
        self.friendsManager = friendsManager
        self.eventsManager = eventsManager
        self.nearbyManager = nearbyManager
        
        super.init()
        
        nearbyManager.isScanning.sink {
            self.isScanning = $0
        }.store(in: &cancellables)
        
        eventsManager.$eventsToShare.receive(on: RunLoop.main).sink(receiveValue: { _ in
            self.reload()
        })
        .store(in: &cancellables)
    }
    
    private func reload() {
        myEvents = eventsManager.myCurrentEvents.map {
            .init(
                id: $0.id.uuidString,
                title: $0.title,
                date: $0.date.ISO8601Format(),
                source: "Created by me",
                responses: $0.responses.summary
            )
        }
        
        othersEvents = eventsManager.receivedEvents.map {
            let creator = friendsManager.friend(for: $0.event.creatorID)
            let creatorUUID = creator?.device.id ?? $0.event.creatorID
            
            var source = "Created by \(creator?.name ?? creatorUUID)"
            
            if creatorUUID != $0.sender.device.id {
                source += "\nReceived from \($0.sender.name)"
            }
            
           return .init(
                id: $0.event.id.uuidString,
                title: $0.event.title,
                date: $0.event.date.ISO8601Format(),
                source: source,
                responses: $0.event.responses.summary
            )
        }
    }

    func addEvent(title: String, date: Date) {
        eventsManager.createEvent(
            .init(
                id: .init(),
                title: title,
                date: date,
                lastUpdate: .now,
                responses: [.init(responderID: userUUID, going: .host, lastUpdate: .now)],
                creatorID: userUUID
            )
        )
        
        sendEvents()
    }
    
    func sendEvents() {
        friendsManager.shareEventsWithNearbyFriends().sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
    }
    
    func searchTapped() {
        nearbyManager.searchForNearbyDevices()
    }
    
    func eventTapped(_ item: EventListItem) {     
        guard let event = (eventsManager.myCurrentEvents + eventsManager.receivedEvents.map { $0.event })
            .first(where: { $0.id.uuidString == item.id }) else { return }
        detailViewModel = .init(event: event, friendManager: friendsManager, eventManager: eventsManager)
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
                Text(event.responses)
                    .font(.footnote)
            }
            
            Spacer()
            
            Text(event.source).font(.footnote).multilineTextAlignment(.trailing)
        }
    }
}

struct EventsList: View {
    @StateObject var viewModel: EventsListViewModel
    @State var showAddEvent: Bool = false
    
    var body: some View {
        VStack {
            List {
                Section("Mine") {
                    ForEach(viewModel.myEvents) { event in
                        Button {
                            viewModel.eventTapped(event)
                        } label: {
                            EventListItemView(event: event)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button("Add Event") {
                        showAddEvent = true
                    }
                }
                
                Section("Others'") {
                    ForEach(viewModel.othersEvents) { event in
                        Button {
                            viewModel.eventTapped(event)
                        } label: {
                            EventListItemView(event: event)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Button("Send Events") {
                viewModel.sendEvents()
            }
        }
        .toolbar {
            Button {
                viewModel.searchTapped()
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
        .sheet(item: $viewModel.detailViewModel) { viewModel in
            EventDetailView(viewModel: viewModel)
        }
    }
}
