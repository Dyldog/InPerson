//
//  ContentView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI
import Combine

struct EventListItem: Identifiable {
    var id: String { title + date.ISO8601Format() }
    let title: String
    let date: Date
    let creator: String
}

class EventsListViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager = .shared
    let eventsManager: EventsManager = .shared
    let bluetoothManager: BluetoothManager = .shared
    
    @Published var myEvents: [EventListItem] = []
    @Published var othersEvents: [EventListItem] = []
    
    @Published var isScanning: Bool = false
    var cancellables: Set<AnyCancellable> = .init()
    
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
            .init(title: $0.title, date: $0.date, creator: "Me")
        }
        
        othersEvents = eventsManager.receivedEvents.map {
            .init(title: $0.event.title, date: $0.event.date, creator: $0.sender.name)
        }
    }

    func addEvent(_ event: Event) {
        eventsManager.createEvent(event)
        friendsManager.shareEventsWithNearbyFriends()
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)

    }
}

struct EventListItemView: View {
    let event: EventListItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.title)
                Text(event.date.ISO8601Format())
                    .font(.footnote)
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Received from").font(.footnote)
                Text(event.creator).font(.footnote)
            }
        }
    }
}

struct EventsList: View {
    @StateObject var viewModel: EventsListViewModel = .init()
    @State var showAddEvent: Bool = false
    
    var body: some View {
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
        .toolbar {
            Button {
                BluetoothManager.shared.scanForDevices()
            } label: {
                Circle().foregroundColor(viewModel.isScanning ? .green : .red)
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventsView() {
                viewModel.addEvent($0)
                showAddEvent = false
            }
        }
    }
}
