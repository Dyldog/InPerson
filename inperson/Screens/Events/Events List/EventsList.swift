//
//  ContentView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI
import Combine

var userUUID: String = UIDevice.current.identifierForVendor?.uuidString ?? "ERROR!!!"

struct EventsList: View {
    @StateObject var viewModel: EventsListViewModel
    
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
                        viewModel.showAddEvent = true
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
                
                if !viewModel.pastEvents.isEmpty {
                    Section("Past") {
                        ForEach(viewModel.pastEvents) { event in
                            EventListItemView(event: event)
                        }
                    }
                }
            }
        }
        .toolbar {
            Button {
                viewModel.searchTapped()
            } label: {
                Circle().foregroundColor(viewModel.isScanning ? .green : .red)
            }
        }
        .sheet(isPresented: $viewModel.showAddEvent) {
            AddEventsView(viewModel: viewModel.addEventsViewModel())
        }
        .sheet(item: $viewModel.detailViewModel) { viewModel in
            EventDetailView(viewModel: viewModel)
        }
    }
}

struct EventsList_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventsList(viewModel: .init(
                friendsManager: MockFriendsManager(friends: .mock),
                eventsManager: MockEventsManager(
                    myCurrentEvents: .mock,
                    receivedEvents: [Event].mock.map {
                        .init(event: $0, sender: [Friend].mock.randomElement()!)
                    },
                    pastEvents: []
                ),
                nearbyManager: MockNearbyConnectionManager()
            ))
        }
    }
}
